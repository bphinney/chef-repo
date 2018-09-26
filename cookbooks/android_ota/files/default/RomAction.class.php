<?php
/**
 *
 * api class of OTA
 * author hercules
 *
 */
class RomAction extends HomeAction{
	function ota() {
		$mac=trim($_REQUEST['mac']);
		$model=trim($_REQUEST['model']);
		$firmware=trim($_REQUEST['firmware']);
		$lang=trim($_REQUEST['lang']);
		$data['status']='lastest';
		$isTest=false;
		$isTestBox=false;
		if (!empty($model)&&!empty($firmware)) {
			$key='getOtaModelByName_'.$model;
			$kbox=S($key);
			if (empty($kbox)) {
				$where['model']=$model;
				$kbox=M('kbox')->where($where)->field('id,model')->find();
				if (!empty($kbox)) {
					S($key,$kbox);
				}
			}
			if (!empty($kbox)&&!empty($firmware)) {
				$key='getRomListByKidAndVersion_'.$kbox['kid'].'_'.$firmware;
				$romList=S($key);
				if (empty($romList)) {
					$wh['kid']=$kbox['id'];
					$wh['status']=1;
					$wh['oversion']=array('like','%'.$firmware.'%');
					$romList=M('ota_rom')->where($wh)->order('cversion desc')->field('id,cversion version,oversion,zipurl url,md5,mac,popup,count')->select();
					if (!empty($romList)) {
						S($key,$romList);
					}
				}
				if (!empty($romList)) {
					$isFound=false;
					$curPos=0;
					if(count($romList)>1){
						usort($romList,function($a,$b){
							return -(version_compare($a['version'],$b['version']));
						});
					}
					foreach ($romList as $rom) {
						$versionList=explode(',', $rom['oversion']);
						foreach ($versionList as $kk=>$versionItem) {
							if ($firmware==trim($versionItem)) {
								$isFound=true;
								$curPos=$kk;
								break;
							}
						}
						if ($isFound) {
							$myOta=$rom;
							break;
						}
					}
					if ($isFound&&!empty($myOta)) {
						if (!empty($lang)) {
							$key='getOtaInfoByOidAndCode_'.$myOta['id'].'_'.$lang;
							$info=S($key);
							if (empty($info)) {
								$whh['oi.oid']=$myOta['id'];
								$whh['ol.code']=$lang;
								$prefix=C('DB_PREFIX');
								$info=M('ota_info oi')->join('left join '.$prefix.'ota_lang ol on ol.id=oi.lid')->where($whh)->find();
								if (!empty($info)) {
									S($key,$info);
								}
							}
						}
						if (empty($info)) {
							$key='getOtaInfoByOidAndCode_'.$myOta['id'].'_en';
							$info=S($key);
							if (empty($info)) {
								$whh['oi.oid']=$myOta['id'];
								$whh['ol.code']='en';
								$prefix=C('DB_PREFIX');
								$info=M('ota_info oi')->join('left join '.$prefix.'ota_lang ol on ol.id=oi.lid')->where($whh)->find();
								if (!empty($info)) {
									S($key,$info);
								}
							}
						}
						if (!empty($info['info'])) {
							$infoArray=explode('{||}', $info['info']);
							if (empty($infoArray[$curPos])) {
								$curPos=0;
							}
							$myOta['info']=$infoArray[$curPos];
						}else {
							$myOta['info']=$info['info'];
						}
						if (!empty($myOta['mac'])) {
							$isTest=true;
							if (strpos(strtolower($myOta['mac']),strtolower($mac))!==false) {
								$isTestBox=true;
							}
						}
						unset($myOta['id']);
						unset($myOta['mac']);
						unset($myOta['oversion']);
						unset($myOta['count']);
					}
				}
			}
		}
		if (!empty($myOta)) {
			$data['status']='update';
			$data['data']=$myOta;
		}
		if ($isTest) {
			if ($isTestBox) {
				echo json_encode($data);
			}else {
				$data['status']='lastest';
				unset($data['data']);
				echo json_encode($data);
			}
		}else{
			echo json_encode($data);
		}
	}
}
?>