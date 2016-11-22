<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.PrintWriter,

alix.fr.Tag,
alix.fr.Occ,
alix.fr.OccSlider,
alix.fr.Tokenizer
"%>
<%@include file="common.jsp" %>
<% request.setCharacterEncoding("UTF-8"); %>
<!DOCTYPE html>
<html>
  <head>
    <title>Concordance rapide</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
  </head>
  <body>
    <article>
      <h1><a href=".">Alix</a> : chercher un mot</h1>
          <form method="get">
          <% String mot = request.getParameter( "mot" ); if (mot == null) mot =""; %>
          <input name="mot" value="<%= mot %>"/> <button type="submit">chercher</button> dans
          <br/>
      <select name="bibcode" onchange="this.form.submit()">
      <%
        String bibcode = request.getParameter("bibcode");
        seltext( pageContext, bibcode );
      %>
      </select>
      </form>
 <% 
String text = text( pageContext, bibcode );
while (!"".equals( mot )) {
  if ( text == null ) {
    if ( bibcode == null && "".equals( bibcode )) break;
    out.print( "<p>Le texte "+bibcode+" n’est pas disponible sur ce serveur.</p>\n");
    break;
  }
  out.println("<section class=\"conc\">" );
  Tokenizer toks = new Tokenizer( text );
  int left = 50;
  int right = 50;
  OccSlider win = new OccSlider(left, right);
  while  ( toks.word( win.add() ) ) {
    if ( !win.get( 0 ).lem.equals( mot ) ) continue;
    if ( !win.get( 0 ).orth.equals( mot ) ) continue;
    out.println( "<p>" );
    for ( int i=-left; i<=right; i++ ) {
      if ( i==0 ) {
        out.println( "<b>" );
      }
      win.get( i ).print( new PrintWriter(out) );
      if ( i==0 ) {
        out.print( "</b>" );
      }
    }
    out.print( "</p>" );
  }
  out.println("</section>" );
  break;
}
%>
    </article>

</html>