<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.PrintWriter,
java.util.Map,
java.util.List,

alix.fr.Lexik,
alix.fr.Occ,
alix.fr.OccSlider,
alix.fr.Tag,
alix.util.TermDic,
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
    <article id="top">
      <h1><a href=".">Alix</a> : chercher un mot (<a href="#cooc">Cooccurrents</a>)</h1>
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
TermDic coocs = new TermDic();
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
      if ( i < -10 || i == 0 || i > 11 );
      else if ( !win.get( i ).lem.isEmpty(  ) ) coocs.inc( win.get( i ).lem );
      else  coocs.inc( win.get( i ).orth ) ;
      if ( i==0 ) out.println( "<b>" );
      win.get( i ).print( new PrintWriter(out) );
      if ( i==0 ) out.print( "</b>" );
    }
    out.print( "</p>" );
  }
  out.println("</section>" );
  break;
}
%>
    </article>
    <article id="cooc">
      <h2><a href="#top">▲</a>Cooccurrents</h2>
      <p>
      <%
List<Map.Entry<String, int[]>> mots = coocs.entriesByCount();
int limit = 200;
boolean first = true;
String term;
int count;
for( Map.Entry<String, int[]> entry: mots ) {
  limit --;
  term = entry.getKey();
  if ( term.isEmpty() ) continue;
  count = entry.getValue()[TermDic.ICOUNT];
  if ( count < 2 ) break;
  if ( Lexik.isStop( term )) continue;
  if ( first ) first=false;
  else out.print(", ");
  out.print( term );
  out.print(" (");
  out.print( count );
  out.print(")");
  if (limit <= 0) break;
}
      %>
      </p>
    </article>

</html>