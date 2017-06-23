<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@include file="common.jsp" %>
<%
  int leftmax = -50;
int left = -5;
try { left = Integer.parseInt( request.getParameter( "left" ) ); } catch (Exception e) {}
if ( left < -30 && left > 0) left = -5;

int rightmax = 50;
int right = 5;
try { right = Integer.parseInt( request.getParameter( "right" ) ); } catch (Exception e) {}
if ( right < 0 || right > 30) right = 5;

String q = request.getParameter( "q" );
if (q == null) q ="";
%>
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
        <input name="q" value="<%=q%>"/>
        Cooccurence, entre
       <input size="2" name="left" value="<%=left%>"/>
       et
       <input size="2" name="right" value="<%=right%>"/>
       mots
       <button type="submit">chercher</button> 
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
   DicFreq coocs = new DicFreq();
   int limit = 1000; // limiter les occurrences affichées
   if ( text == null ) {
     if ( bibcode != null && !"".equals( bibcode ))
   out.print( "<p>Le texte "+bibcode+" n’est pas disponible sur ce serveur.</p>\n");
   }
 %>
  <div class="conc">
  <%
    int n = 0;
    if ( text != null && q != null && !q.trim().isEmpty() ) {
      Tokenizer toks = new Tokenizer( text );
      OccRoller win = new OccRoller(leftmax, rightmax);
      while  ( toks.word( win.add() ) ) {
    if ( !win.get( 0 ).lem().equals( q ) && !win.get( 0 ).orth().equals( q ) ) continue;
    n++;
    out.println( "<p>"+n+" — " );
    for ( int i = leftmax; i <= rightmax; i++ ) {
      // cooccurents
      if ( i < left || i == 0 || i > right );
      else if ( !win.get( i ).lem().isEmpty(  ) ) {
        coocs.inc( win.get( i ).lem() );
      }
      else  coocs.inc( win.get( i ).orth() ) ;
      if ( i == left ) out.println( "<mark>" );
      if ( i == 0 ) out.println( "<b>" );
      Tokenizer.write( out, win.get( i ) );
      if ( i==0 ) out.print( "</b>" );
      if ( i == right ) out.println( "</mark>" );
    }
    out.print( "</p>" );
      }
    }
  %>
    </div>
  </div>
    <div id="cooc" style="float: left; padding: 1ex; ">
      <div style=" position:fixed; width: 50ex; ">
      <h2><%=n%> extraits, cooccurrence :</h2>
      <p>
      <%
        limit = 200;
      boolean first = true;
      String term;
      int count;
      for( Entry entry: coocs.byCount() ) {
        limit --;
        term = entry.label();
        // if ( term.isEmpty() ) continue;
        count = entry.count();
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