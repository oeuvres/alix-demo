<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.util.Collection,
java.util.Collections,
java.util.Comparator,
java.util.HashMap
" %><%@include file="common.jsp"
%><%!

int forget;
final static public short SIZE = 1;
final static public short MIN = 2;
final static public short MAX = 3;
final static public short AVG = 4;
final static public short SUM = 5;

// private int forget;



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

/**
 * Plot all distances by pos
 */
private void distances( final IntSeries[] table ) throws IOException
{
  int width = forget;
  int[][] mat = new int[5][width+1];
  final int NAME = 0;
  final int SUB = 1;
  final int VERB = 2;
  final int ADJ = 3;
  final int STOP = 4;
  // int step = 1;
  // distribute values
  int max = 0;
  for ( IntSeries word:table) {
    // if ( word.size() < filterlow ) continue;
    int[] row;
    if ( Lexik.isStop( word.label ) ) row = mat[STOP];
    else if ( Tag.isSub( word.cat )) row = mat[SUB];
    else if ( word.cat == Tag.VERB ) row = mat[VERB];
    else if ( Tag.isName( word.cat )) row = mat[NAME];
    else if ( Tag.isAdj( word.cat )) row = mat[ADJ];
    else row = mat[STOP];
    int size = word.size();
    for ( int i=0; i < size; i++ ) {
      // int val = (int)Math.ceil( row.get( i ) / step ) * step;
      int val = word.get( i );
      max = Math.max( max, val );
      row[val]++;
    }
  }
  int wing = max/100;
  for ( int i=0; i <= max; i=i+1 ) {
    printer.print( "[" );
    printer.print( i );
    for ( int[] row: mat ) {
      printer.print( ", " );
      // sliding avg
      int from = Math.max( 0, i-wing );
      int to = Math.min( width, i+wing );
      double avg = 0;
      for ( int j=from; j <=to; j++) avg += row[j];
      avg = avg / (1.0+to-from);
      avg = Math.max( 1, avg );
      printer.print( avg );
    }
    printer.println( "]," );
  }
  // 33 ms, no problem
  // System.out.println( "// "+( (System.nanoTime() - time ) / 1000000) + " ms");
  
}


public String human( double x )
{
  String label;
  if ( x > 2000000000 ) label = new DecimalFormat("#", frsyms).format( x/1000000000 )+"G";
  else if ( x > 2000000 ) label = new DecimalFormat("#", frsyms).format( x/1000000 )+"M";
  else if ( x > 2000 ) {
    double m =  x/1000;
    if ( m < 10 ) label = new DecimalFormat("#.00", frsyms).format( m )+"K";
    else label = new DecimalFormat("#", frsyms).format( m )+"K";
  }
  else if ( x < 1 ) {
    label = new DecimalFormat("0.00", frsyms).format( x );
  }
  else label = ""+(int)x;
  return label;
}

/**
 * Give nice limits for graphics
 */
private double[] limits( final double min, final double max, boolean log ) throws IOException
{
  double[] ret = new double[3];
  if ( log ) {
    double step = Math.pow( 10, Math.floor(Math.log10( max )));
    ret[2] = Math.ceil( max / step ) * step; 
    step = Math.pow( 10, Math.floor(Math.log10( min-min/10 )));
    ret[1] = Math.floor( min / step ) * step; 
    return ret;
  }

   // optimal number of ticks
  int optimal = 50;
  // (150, 27000) -> (0, 30000)
  double width = max - min;
  // find correct magnitude from biggest limit
  long mag = Math.round( Math.log10( max - min ) );
  // find best tick
  double tick = Math.pow( 10, mag-3 );
  double tickbest = -1;
  double lastdif = -1;
  for ( int i:new int[]{1, 2, 5, 10, 20, 50} ) {
    // number of ticks compared to optimal
    double dif = Math.abs( optimal - (width / (tick*i))) ;
    // first, always record, go next
    // last is better, keep it
    if ( lastdif > 0 && lastdif < dif ) continue;
    lastdif = dif;
    tickbest = tick * i;
  }
  ret[0] = tickbest;
  ret[1] = Math.floor( min/(ret[0]*5)) * 5 * ret[0];
  ret[2] = Math.ceil( max/(ret[0]*5)) * 5 * ret[0];
  return ret;
}

private void scatterhtml( final IntSeries[] table ) throws IOException
{
  String title = "Répétitions : nombre et distance moyenne";
  String xleg = "Distance moyenne (caractères)";
  String yleg = "Répétitions (nombre)";
  boolean xlog = false;
  boolean ylog = true;
  // int decil = 5;
  // get max and min from table
  double xmin = table[0].avg;
  double xmax = table[0].avg;
  double ymin = table[0].size();
  double ymax = table[0].size();
  for ( IntSeries row:table) {
    if ( row.size() < filterlow ) continue;
    xmin = Math.min( xmin, row.avg );
    xmax = Math.max( xmax, row.avg );
    ymin = Math.min( ymin, row.size() );
    ymax = Math.max( ymax, row.size() );
  }
  double[] x = limits( xmin, xmax, false );
  double[] y = limits( ymin, ymax, true );
  double ylogw = Math.log10( y[2] - y[1] );

  printer.println( "<div class=\"scatter\">" );
  printer.println( "<div class=\"title\">"+title+"</div>" );
  printer.println( "<div class=\"xleg\">"+xleg+"</div>" );
  printer.println( "<div class=\"yleg\">"+yleg+"</div>" );
  
  printer.println( "<div class=\"legend\">" );
  printer.println( "<div class=\"dot name\"><b>●</b> Nom propre</div>" );
  printer.println( "<div class=\"dot sub\"><b>●</b> Substantif</div>" );
  printer.println( "<div class=\"dot adj\"><b>●</b> Adjectif</div>" );
  printer.println( "<div class=\"dot verb\"><b>●</b> Verbe</div>" );
  printer.println( "<div class=\"dot adv\"><b>●</b> Adverbe</div>" );
  printer.println( "<div class=\"dot\"><b>●</b> Autres</div>" );
  printer.println( "</div>" );
  // ygrid
  printer.println( "<div class=\"dots\">" );
  if ( ylog ) {
    double tick = y[2];
    double step = Math.pow( 10, Math.floor(Math.log10( tick-1 )));
    tick = Math.floor( tick / step ) * step; // 35000 -> 30000 
    double bottom;
    while ( tick >= y[1] ) {
      if ( (tick - y[1]) == 0 ) bottom = 0;
      else bottom = Math.round( 10000.0 * ( Math.log10( 1+tick - y[1] ) ) / ylogw )/100.0; // +1 log(1) = 0
      printer.print( "<div class=\"ygrid\" style=\"bottom: "+bottom+"%;\">");
      printer.print( human(tick) );
      printer.println("</div>" );
      // power of ten
      step = Math.pow( 10, Math.floor(Math.log10( tick )-0.0001));
      if ( bottom == 0 ) break; // negative log ?
      tick = tick - step;
    }
  }
  // xgrid
  if (xlog) {
    
  }
  else {
    double tick = x[1];
    printer.println( "<div class=\"xgrid first\" style=\"left: 0%;\"><span>"+human( x[1] )+"</span></div>" );
    printer.println( "<div class=\"xgrid last\" style=\"right: 0%;\"><span>"+human( x[2] )+"</span></div>" );
    double left = 0;
    tick += x[0];
    while ( tick < x[2] ) {
      left = 10000.0*tick/( x[2] - x[1] )/100.0;
      String mod = "";
      if ( (tick/ x[0]) % 10 == 0 ) mod=" mod10";
      if ( (tick/ x[0]) % 2 == 0 ) mod+=" odd";
      else mod=" even";
      printer.print( "<div class=\"xgrid"+mod+"\" style=\"left: "+left+"%;\"><span>");
      printer.print( human(tick) );
      printer.println("</span></div>" );
      tick += x[0];
    }
  }

  int limit = 10000;
  int i = 0;
  for ( IntSeries row:table) {
    if ( i >= limit ) break;
    if ( row.size() < filterlow ) continue;
    if ( row.count < filterlow ) break;
    i++;
    // double left = ;
    double left = Math.round( 10000.0 * ( row.avg - x[1] ) / ( x[2]-x[1] ) )/100.0 ;
    double bottom;
    if ( (row.size() - y[1]) == 0 ) bottom = 0; 
    else bottom = Math.round( 10000.0 * ( Math.log10( 1+row.size() - y[1] ) ) / ylogw )/100.0; // +1 log(1) = 0
    
    String cat = "";
    if ( Tag.isSub( row.cat )) cat = "sub";
    else if ( Tag.isVerb( row.cat )) cat = "verb";
    else if ( Tag.isName( row.cat )) cat = "name";
    else if ( row.cat == Tag.ADV ) cat = "adv";
    else if ( Tag.isAdj( row.cat )) cat = "adj";
    String label = row.label+" ("+row.count+" occs, "+row.size()+" reps, DMR="+(int)row.avg+")";
    printer.print( "<div class=\"dot "+cat+"\" style=\"left: "+left+"%; bottom: "+bottom+"%;\">" );
    printer.print( "<b>●</b>" ); // ⬤
    printer.print( "<span> "+label+"</span>" );
    printer.println( "</div>");
  }

  printer.println( "</div>" );
  printer.println( "</div>" );
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
    printer.print( row.decile(5) );
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
forget = 10000;
try { forget = Integer.parseInt( request.getParameter( "forget" ) ); } catch (Exception e) {}
if ( forget <= 0 ) forget = -1;

int filterlow = 1;
try { filterlow = Integer.parseInt( request.getParameter( "filterlow" ) ); } catch (Exception e) {}
if ( filterlow < 1 ) filterlow = 1;
this.filterlow = filterlow;

%><!DOCTYPE html>
<html>
  <head>
    <title>Répétitions</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
    <link rel="stylesheet" type="text/css" href="lib/dygraph.css" />
    <style>
table.freqlist { float: left; margin-right: 1ex;}
    </style>
    <script src="lib/dygraph.min.js">//</script>
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
        <label>Filtre bas <input size="2" name="filterlow" value="<%=filterlow%>"/></label>
        <label title="Distance d’oubli">Oubli <input size="4" name="forget" value="<%=forget%>"/></label>
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
            if ( forget > -1 && dif >= forget ) continue;
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
        %>
<div id="chart" class="dygraph" style="width:100%; height:600px; background: #FFFFFF; margin: 2em 0; "></div>
<script type="text/javascript">
g = new Dygraph(
  document.getElementById("chart"),
  [ 
  <% distances( table ); %>
  ],
  {
    labels: [ "Distance", "Noms", "Substantifs", "Verbes", "Adjectifs", "Grammaticaux" ],
    legend: "always",
    labelsSeparateLines: "true",
    title: "Répétitions, distribution par distance et catégorie morpho-syntaxique",
    ylabel: "Répétitions (nombre)",
    xlabel: "Distance (en caractères)",
    // showRoller: true,
    // rollPeriod: <%=(int)forget/30%>,
    series: {
      "Noms": { color: "rgba( 0, 128, 0, 1 )", strokeWidth: 3 },
      "Substantifs": { color: "rgba( 0, 0, 128, 1 )", strokeWidth: 3 },
      "Verbes": { color: "rgba( 255, 0, 0, 1 )", strokeWidth: 3 },
      "Adjectifs": { color: "rgba( 0, 128, 255, 1 )", strokeWidth: 3 },
      "Adverbes": { color: "rgba( 255, 128, 0, 1 )", strokeWidth: 3 },
      "Grammaticaux": { color: "rgba( 128, 128, 128, 1 )", strokeWidth: 3 },
    },
    logscale: true,
    axes: {
      x: {
        // logscale: true, // ne marche pas si un seul 0
        // gridLineWidth: 1,
        // gridLineColor: "rgba( 255, 0, 0, 0.2)",
        // drawGrid: true,
        // independentTicks: true,
      },
      y: {
        // logscale: 1,
        // independentTicks: true,
        // drawGrid: true,
        // axisLabelColor: "rgba( 255, 0, 0, 0.9)",
        // gridLineColor: "rgba( 255, 0, 0, 0.2)",
        // gridLineWidth: 1,
      },
    },
  }
);
</script>
      <%
        scatterhtml( table );
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
            return Double.compare( row2.devstd/row2.avg, row1.devstd/row1.avg );
          }
        } );
        table( table, 100, "Tri + éparpillé", filterlow, false );

        Arrays.sort( table, new Comparator<IntSeries>()
        {
          @Override
          public int compare( IntSeries row1, IntSeries row2 )
          {
            return Double.compare( row1.devstd/row1.avg, row2.devstd/row2.avg );
          }
        } );
        table( table, 100, "Tri + homogène", filterlow, false );


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
