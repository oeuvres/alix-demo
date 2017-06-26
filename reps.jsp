<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.util.Collection,
java.util.Collections,
java.util.Comparator,
java.util.HashMap
" %><%@include file="common.jsp" 
%><%!final static public short SIZE = 1;
final static public short MIN = 2;
final static public short MAX = 3;
final static public short AVG = 4;
final static public short SUM = 5;
private int forget;

final static private int svgwidth = 10000;
final static private int svgheight = 5000;
final static private int svgbottom = 0;
final static private int svgtop = 400;
final static private int svgleft = 400;
final static private int svgright = 400;
private int xmax;
private int ymax;
private double ylogmax;
private double xlogmax;
private int filterlow;

private int dotx( IntSeries row )
{
  double value = (svgwidth - svgleft - svgright ) * row.avg / forget;
  return (int)value + svgleft;
  // double value =  Math.log10( row.size() ) * ( svgwidth - svgleft - svgright ) / xlogmax;
  // double value =  row.size()  * ( svgwidth - svgleft - svgright ) / xmax;
  // return svgwidth - (int)value - svgright;
}
private int doty( IntSeries row )
{
  double value = (Math.log10( row.count - filterlow ) ) * ( svgheight - svgtop - svgbottom ) / ylogmax;
  // double value = row.count * ( svgheight - svgtop - svgbottom ) / ymax;
  return ( svgheight - svgtop - svgbottom ) - (int) value + svgtop;
}

private void svg( final IntSeries[] table ) throws IOException
{
  int limit = 10000;
  
  this.ymax = table[0].count;
  this.ylogmax = Math.log10( this.ymax );
  this.xmax = table[0].size();
  this.xlogmax = Math.log10( table[0].size() );
  
  printer.println( "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" class=\"scatter\" viewBox=\"0 0 "+svgwidth+" "+svgheight+"\">" );
  int i = 0;
  // TODO axex and grid
  
  for ( IntSeries row:table) {
    if ( i >= limit ) break;
    if ( row.size() < filterlow ) continue;
    if ( row.count < filterlow ) break;
    i++;
    int x = dotx( row );
    int y = doty( row );
    
    String cat = "";
    if ( Tag.isSub( row.cat )) cat = "sub";
    else if ( Tag.isVerb( row.cat )) cat = "verb";
    else if ( Tag.isName( row.cat )) cat = "name";
    else if ( row.cat == Tag.ADV ) cat = "adv";
    else if ( Tag.isAdj( row.cat )) cat = "adj";
    
    printer.println( "<g class=\"dot "+cat+"\" transform=\"translate("+x+", "+y+")\">" );
    printer.println( "<text>"+row.label+" ("+row.count+" occs, "+row.size()+" reps, DMR="+(int)row.avg+")"+"</text>" );
    printer.println( "<circle r=\"50\"/>");
    printer.println( "</g>");
  }
  printer.println( "</svg>" );
}

private void table( final IntSeries[] table, final int limit, final String caption, int filterlow, boolean stop ) throws IOException
{
  printer.println( "<table class=\"sortable freqlist\">" );
  printer.println( "<caption>"+caption+"</caption>" );
  printer.println( "<tr><th>Mot</th><th>Occs</th><th>Reps</th><th>DMR</th><th>min</th><th>med</th><th>max</th><th>σ</th></tr>" );
  int i = 0;
  for ( IntSeries row:table) {
    if ( i >= limit ) break;
    if ( row.size() < filterlow ) continue; // à partir de combien ?
    if ( stop && Lexik.isStop( row.label ) ) continue; // à partir de combien ?
        
    i++;
    printer.println("<tr>");
    printer.print("<td align=\"right\"><b>");
    printer.print( row.label );
    printer.println("</b></td>");
    printer.print("<td align=\"right\">");
    printer.print( row.count );
    printer.println("</td>");
    printer.print("<td align=\"right\">");
    printer.print( row.size() );
    printer.println("</td>");
    printer.print("<td align=\"right\">");
    printer.print( (int)row.avg );
    printer.println("</td>");
    printer.print("<td align=\"right\">");
    printer.print( row.min );
    printer.println("</td>");
    printer.print("<td align=\"right\">");
    printer.print( row.median );
    printer.println("</td>");
    printer.print("<td align=\"right\">");
    printer.print( row.max );
    printer.println("</td>");
    printer.print("<td align=\"right\">");
    printer.print( (int)row.devstd );
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
*/%><%
this.printer = out;
String bibcode = request.getParameter("bibcode");
int forget = 10000;
try { forget = Integer.parseInt( request.getParameter( "forget" ) ); } catch (Exception e) {}
if ( forget < 1 ) forget = 10000;
this.forget = forget;

int filterlow = 1;
try { filterlow = Integer.parseInt( request.getParameter( "filterlow" ) ); } catch (Exception e) {}
if ( filterlow < 1 ) filterlow = 1;
this.filterlow = filterlow;

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
        <label title="Distance de l’oubli (en caractères)">Oubli <input size="4" name="forget" value="<%=forget%>"/></label>
        <label>Filtre bas <input size="2" name="filterlow" value="<%=filterlow%>"/></label>
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
        HashMap<String,IntSeries> dico = new HashMap<String,IntSeries>();
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
          IntSeries list = dico.get( occ.lem() );
          if ( list == null ) {
            String key = occ.lem().toString();
            int cat = occ.tag().code();
            list = new IntSeries( key, cat );
            list.last = after;
            list.count++;
            dico.put( key, list );
            continue;
          }
          if ( list.last > 0 ) {
            list.count++;
            dif =  before - list.last;
            list.last = after;
            if ( forget > 0 && dif > forget ) continue;
            // if ( dif < 2 && occ.lem().equals( "venir" ) ) System.out.println( occ.lem()+" — "+ text.substring( occ.start()-20, occ.end()+20 ));
            list.push( dif );
          }
        }
        IntSeries[] table = dico.values().toArray( new IntSeries[0] );
        // loop on all list before sort, to cache values
        for ( IntSeries row: table ) {
          row.cache();
        }
        
        // Fréquence
        Arrays.sort( table, new Comparator<IntSeries>()
        {
          @Override
          public int compare( IntSeries row1, IntSeries row2 )
          {
            return Integer.compare( row2.count, row1.count );
          }
        } );
        svg( table );
        %>
     <script>
var els = Array.from(document.querySelectorAll('svg .dot'));
// add event listeners
els.forEach(function(el) {
  el.addEventListener("mouseover", dotHover);
})
function dotHover() {
	// console.log(this);
}
     </script>
        <%
        
        table( table, 100, "Tri fréquence &gt;", filterlow, false );
        table( table, 100, "Tri fréquence &gt; (-mots gram.)", filterlow, true );


        Arrays.sort( table, new Comparator<IntSeries>()
        {
          @Override
          public int compare( IntSeries row1, IntSeries row2 )
          {
            return Double.compare( row2.avg, row1.avg );
          }
        } );
        table( table, 100, "Tri DMR &gt;", filterlow, false );

        Arrays.sort( table, new Comparator<IntSeries>()
        {
          @Override
          public int compare( IntSeries row1, IntSeries row2 )
          {
            return Double.compare( row1.avg, row2.avg );
          }
        } );
        table( table, 100, "Tri DMR &lt;", filterlow, false );

        Arrays.sort( table, new Comparator<IntSeries>()
        {
          @Override
          public int compare( IntSeries row1, IntSeries row2 )
          {
            return Double.compare( row2.devstd, row1.devstd );
          }
        } );
        table( table, 100, "Tri écart-type &gt;", filterlow, false );


        // resort on size
        Arrays.sort( table, new Comparator<IntSeries>()
        {
          @Override
          public int compare( IntSeries row1, IntSeries row2 )
          {
            return Integer.compare( row2.count, row1.count );
          }
        } );
        
        out.println("<textarea style=\"height: 10em; width:100%; \">");
        out.println( "MOT\tOCCS\tREPS\tDMR" );
        for ( IntSeries row:table ) {
          if ( row.size() < 1 ) break;
          out.println( row.label+"\t"+row.count+"\t"+row.size()+"\t"+(int)row.avg );
        }
        out.println("</textarea>");
      }
      %>
     </article>
    <script src="lib/Sortable.js">//</script>
  </body>
 </html>
