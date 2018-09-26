<%@ page import="java.io.*,java.util.*" %><%@ page import="java.io.*" %><%@ page import="java.net.*" %><%

// TODO: this script needs to be protected from unauthorised access
// or it could be mis-used as a anonymous proxy

  // headers
  response.setHeader("Cache-Control", "no-cache");
	response.setDateHeader("Expires", 0);
	response.setHeader("Pragma", "No-cache");

  // get posted data
  Enumeration paramNames = request.getParameterNames(); 

  // construct querystring
  String params = "";
  String host = "";
  while(paramNames.hasMoreElements()) {
    String paramName = (String)paramNames.nextElement();
    String paramValue = request.getParameter(paramName);
    if(paramName.equals("url")) {
      host = paramValue;
    } else {
      params += paramName.trim() + '=' + URLEncoder.encode(paramValue.trim()) + '&';
    }
  }
  if(host.equals("")) {
    //out.println(params);
    out.println("No host specified");
  } else {
    // fetch webpage
    String recv;
    String recvbuff = "";
    String url = host + "?" + params;
    URL webpage = new URL(url);
    URLConnection urlcon = webpage.openConnection();
    BufferedReader buffread = new BufferedReader(new InputStreamReader(urlcon.getInputStream()));
    while ((recv = buffread.readLine()) != null)
      recvbuff += recv;
    buffread.close();

    // done
    // return recvbuff;
    out.println(recvbuff.trim());
  }
%>