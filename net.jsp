<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<% request.setCharacterEncoding("UTF-8"); %>
<!DOCTYPE html>
<html>
  <head>
    <title>Réseau de noms propres</title>
    <link rel="stylesheet" type="text/css" href="http://svn.code.sf.net/p/obvil/code/theme/obvil.css" />
  </head>
  <body>
    <article id="article">
    <h1><a href=".">Alix</a> : réseau de noms propres</h1>
    
      <%
String text = request.getParameter( "text" );
if ( text == null) text = "";
      %>
      <form method="post" action="netcsv.jsp">
        <textarea name="text" style="width: 100%; height: 10em; "><%= text %></textarea>
        <%
int width = 100;
String swidth = request.getParameter( "width" );
if ( swidth != null) width = Integer.parseInt( swidth );
if ( width < 0 ) width = 100;
        %>
        <label>Fenêtre <input name="width" size="2" value="<%= width %>"/></label>
        <button type="submit">Envoyer</button>
      </form>
     </article>
  </body>
 </html>
