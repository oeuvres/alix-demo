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
    <%@include file="menu.jsp" %>
    <article>
    <div id="top"  style="float: left; ">
      <a href="#top" id="totop">▲</a>
      <h1><a href=".">Alix</a> : chercher un mot</h1>
          <form method="get">
          <% String q = request.getParameter( "q" ); if (q == null) q =""; %>
          <input name="q" value="<%= q %>"/> <button type="submit">chercher</button> dans
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
int limit = 1000; // limiter les occurrences affichées
if ( text == null ) {
  if ( bibcode != null && !"".equals( bibcode ))
    out.print( "<p>Le texte "+bibcode+" n’est pas disponible sur ce serveur.</p>\n");
}
%>
  <div class="conc">
  <% 
if ( text != null && q != null && !q.trim().isEmpty() ) {
  Tokenizer toks = new Tokenizer( text );
  int left = 50;
  int right = 50;
  OccSlider win = new OccSlider(left, right);
  int n = 1;
  while  ( toks.word( win.add() ) ) {
    if ( !win.get( 0 ).lem().equals( q ) && !win.get( 0 ).orth().equals( q ) ) continue;
    out.println( "<p>"+n+" — " );
    for ( int i=-left; i<=right; i++ ) {
      // cooccurents
      if ( i < -10 || i == 0 || i > 10 );
      else if ( !win.get( i ).lem().isEmpty(  ) ) {
        coocs.inc( win.get( i ).lem() );
      }
      else  coocs.inc( win.get( i ).orth() ) ;
      if ( i==0 ) out.println( "<b>" );
      win.get( i ).print( new PrintWriter(out) );
      if ( i==0 ) out.print( "</b>" );
    }
    out.print( "</p>" );
    n++;
  }
}
%>
    </div>
  </div>
    <div id="cooc" style="float: left; padding: 1ex; ">
      <div style=" position:fixed; width: 50ex; ">
      <h2>Cooccurrents</h2>
      <p>
      <%
List<Map.Entry<String,Terminfos>> mots = coocs.entriesByCount();
limit = 200;
boolean first = true;
String term;
int count;
for( Map.Entry<String,Terminfos> entry: mots ) {
  limit --;
  term = entry.getKey();
  // if ( term.isEmpty() ) continue;
  count = entry.getValue().count();
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
      </div>
</article>
</html>