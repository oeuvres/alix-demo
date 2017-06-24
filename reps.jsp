<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.util.Collection,
java.util.Collections,
java.util.Comparator,
java.util.HashMap
" %><%@include file="common.jsp" 
%><%!
final static public short SIZE = 1;
final static public short MIN = 2;
final static public short MAX = 3;
final static public short AVG = 4;
final static public short SUM = 5;

private void table( final IntStack[] table, final int limit, final String caption, boolean stop ) throws IOException
{
  printer.println( "<table class=\"sortable freqlist\">" );
  printer.println( "<caption>"+caption+"</caption>" );
  printer.println( "<tr><th>Mot</th><th>Eff.</th><th>Min.</th><th>Max.</th><th>Moy.</th></tr>" );
  int i = 0;
  for ( IntStack row:table) {
    if ( i >= limit ) break;
    if ( row.size() < 1 ) continue; // à partir de combien ?
    if ( stop && Lexik.isStop( row.label ) ) continue; // à partir de combien ?
        
    i++;
    printer.println("<tr>");
    printer.print("<td>");
    printer.print( row.label );
    printer.println("</td>");
    printer.print("<td align=\"right\">");
    printer.print( row.size() );
    /*
    switch( field ) {
      case SIZE:
        printer.print( row.size() );
        break;
      case MIN:
        printer.print( row.min );
        break;
      case MAX:
        printer.print( row.max );
        break;
      case AVG:
        printer.print( row.avg );
        break;
      case SUM:
        printer.print( row.sum );
        break;
      default:
        printer.print("???");
    }
    */
    printer.println("</td>");
    printer.print("<td align=\"right\">");
    printer.print( row.min );
    printer.println("</td>");
    printer.print("<td align=\"right\">");
    printer.print( row.max );
    printer.println("</td>");
    printer.print("<td align=\"right\">");
    printer.print( (int)row.avg );
    printer.println("</td>");
    printer.println("</tr>");
  }
  printer.println( "</table>" );
}

/*
dist=0
Avoir eu
un des
Les La Fayette
de d’Artagnan
fait faire
trois mille (NUM)
nous nous
Le nouveau venu vint
*/

%><%
this.printer = out;
String bibcode = request.getParameter("bibcode");
int forget = 10000;
try { forget = Integer.parseInt( request.getParameter( "forget" ) ); } catch (Exception e) {}

%><!DOCTYPE html>
<html>
  <head>
    <title>Répétitions</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
    <style>
table.freqlist { float: left; margin-right: 1ex;}
    </style>
  </head>
  <body>
    <%@include file="menu.jsp" %>
    <p></p>
      <form method="GET">
        <a href=".">Alix</a>  
        <select name="bibcode" onchange="this.form.submit()">
          <%
            seltext( pageContext, bibcode );
          %>
        </select>
        <label title="">Oubli <input name="forget" value="<%=forget%>"/></label>
        <button>▶</button>
      </form>
    <article>
      <%
        String text = text( pageContext, bibcode );
      int limit = 1000; // limiter les occurrences affichées
      if ( text == null ) {
        if ( bibcode != null && !"".equals( bibcode ))
          out.print( "<p>Le texte "+bibcode+" n’est pas disponible sur ce serveur.</p>\n");
      }
      else {
        Tokenizer toks = new Tokenizer( text );
        HashMap<String,IntStack> dico = new HashMap<String,IntStack>();
        Occ occ = new Occ();
        int[] entry;
        int pos;
        int dif;
        int before;
        int after = 0;
        while  ( toks.word( occ ) ) {
          before = after;
          after += occ.orth().length()+1; // 
          if ( occ.tag().isPun() ) continue;
          if ( occ.tag().isNum() ) occ.lem( "NUM" );
          // mot inconnu
          if ( occ.lem().isEmpty() ) continue;
          IntStack list = dico.get( occ.lem() );
          if ( list == null ) {
            list = new IntStack();
            String key = occ.lem().toString();
            list.label = key;
            list.last = after;
            dico.put( key, list );
            continue;
          }
          if ( list.last > 0 ) {
            dif =  before - list.last;
            list.last = after;
            if ( forget > 0 && dif > forget ) continue;
            if ( dif < 2 && occ.lem().equals( "venir" ) ) System.out.println( occ.lem()+" — "+ text.substring( occ.start()-20, occ.end()+20 ));
            list.push( dif );
          }
        }
        IntStack[] values = dico.values().toArray( new IntStack[0] );
        // loop on all list before sort, to cache values
        for ( IntStack stack: values ) {
          stack.cache();
        }
        
        // Fréquence
        Arrays.sort( values, new Comparator<IntStack>()
        {
          @Override
          public int compare( IntStack stack1, IntStack stack2 )
          {
            return Integer.compare( stack2.size(), stack1.size() );
          }
        } );
        table( values, 100, "Tri fréquence >", false );
        table( values, 100, "Tri fréquence > (-mots gram.)", true );


        Arrays.sort( values, new Comparator<IntStack>()
        {
          @Override
          public int compare( IntStack stack1, IntStack stack2 )
          {
            return Double.compare( stack2.avg, stack1.avg );
          }
        } );
        table( values, 100, "Tri repétion  moy. >", false );

        Arrays.sort( values, new Comparator<IntStack>()
        {
          @Override
          public int compare( IntStack stack1, IntStack stack2 )
          {
            return Double.compare( stack1.avg, stack2.avg );
          }
        } );
        table( values, 100, "Tri repétion  moy. <", false );

      }
      %>
     </article>
    <script src="lib/Sortable.js">//</script>
  </body>
 </html>
