<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<% request.setCharacterEncoding("UTF-8"); %><%!


%>
<%@include file="common.jsp"%>
<%
String text = request.getParameter( "text" );
DicFreq dic = null;
if ( text != null) {
  Tokenizer toks = new Tokenizer( text );
  Occ occ;
  dic = new DicFreq();
  while ( (occ = toks.word()) != null ) {
    if (!occ.tag().isName()) continue;
    dic.inc(occ.graph(), occ.tag().code());
  }
}
else {
  text = "";
}
%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8"/>
    <title>Index de noms</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
  </head>
  <body>
    <%@include file="menu.jsp"%>
    <article id="article">
      <h1>
        <a href=".">Alix</a> : <a href="?">index de noms</a>
      </h1>
      <p>Soumettre un texte pour en tirer des noms, afin de </p>
      <form method="post" action="">
        <textarea name="text" style="width: 100%; height: 10em; "><%= text %></textarea>
        <button type="submit">Envoyer</button>
      </form>
      <% 
      if ( dic != null ) {
      %>
      <table class="sortable">
        <thead>
          <th>N°</th>
          <th>Nom</th>
          <th>Nombre</th>
          <th>Type</th>
        </thead>
        <%
int i = 1;
for (Entry entry: dic.byCount()) {
  out.write("<tr>");
  out.write("<td class=\'num\'>"+i+"</td>\n");
  out.write("<td class=\'name\'>"+entry.label()+"</td>\n");
  out.write("<td class=\'count\'>"+entry.count()+"</td>\n");
  out.write("<td class=\'type\'>"+ Tag.label( entry.tag() )+"</td>\n");
  i++;
}
        %>
      </table>
      
      <%
      }
      %>
    </article>
    <script src="lib/Sortable.js">//</script>
  </body>
</html>
