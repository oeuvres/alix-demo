<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%@ page import="
java.util.ArrayList,
java.util.Collection,
java.util.Collections,
java.util.concurrent.ThreadLocalRandom,
java.util.Comparator,
java.util.HashMap,
java.util.Random,
alix.util.IntList,
alix.util.TermRoller

" %><%@include file="common.jsp"%><%!
// méthodes

/**
 * Proportion d’occurrences dans le “chapeau” des formes les plus fréquentes
 */
private double hat( final DicFreq dic, final int dicsize ) throws IOException
{
  if ( dic == null ) return 0;
  int[] counts = new int[ dic.size() ];
  int i = 0;
  for ( Entry entry:dic.entries() ) {
    counts[i] = entry.count();
    i++;
  }
  Arrays.sort( counts ); // du + petit au plus grand
  long sum = 0;
  int k=0;
  for ( i=counts.length - 1 ; i >= 0; i-- ) {
    k++;
    sum += counts[i];
    if ( k == dicsize ) return 1.0*sum/dic.occs();
  }
  // pas fini, renvoyer 0 ?
  return 0;

}

// Implementing Fisher–Yates shuffle
static void shuffle( String[] lines )
{
  // If running on Java 6 or older, use `new Random()` on RHS here
  Random rnd = ThreadLocalRandom.current();
  for (int i = lines.length - 1; i > 0; i--)
  {
    int index = rnd.nextInt(i + 1);
    // Simple swap
    String a = lines[index];
    lines[index] = lines[i];
    lines[i] = a;
  }
}

%><%
this.printer = out;
String[] bib = request.getParameterValues("bibcode");
int context = 10000;
try { context = Integer.parseInt( request.getParameter( "context" ) ); } catch (Exception e) {}
if ( context < 1 ) context = 10000;
int step = context / 2;
try { step = Integer.parseInt( request.getParameter( "step" ) ); } catch (Exception e) {}
if ( step < (context/10) ) step = context/10;
int smooth = 0;
try { smooth = Integer.parseInt( request.getParameter( "smooth" ) ); } catch (Exception e) {}
if ( smooth < 0 ) smooth = 0;


%><!DOCTYPE html>
<html>
  <head>
    <title>Lexique</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
    <script src="lib/dygraph.min.js">//</script>
    <link rel="stylesheet" type="text/css" href="lib/dygraph.css" />
    <style>
table.freqlist { float: left; margin-right: 1ex;}
#selcop { display:none }
    </style>
  </head>
  <body>
    <%@include file="menu.jsp" %>
      <h1><a href="?">Variétés</a></h1>
    <form method="GET">
      <fieldset>
        <legend>      
          <button type="button" class="but" onclick="
      var line = document.getElementById('selcop'); 
      var cont = line.parentNode;
      line = line.cloneNode( true );
      line.id = null;
      console.log( line.getElementsByTagName('select') );
      line.getElementsByTagName('select')[0].disabled = false;
      cont.appendChild( line );
      ">+</button>
        </legend>
        <div id="selcop">
          <button type="button" class="but" onclick="this.parentNode.remove(); return false">-</button>
          <select name="bibcode" disabled="disabled">
            <%  seltext( pageContext, null ); %>
          </select>
        </div>
      <% 
      boolean done = false;
      if ( bib == null || bib.length < 1 ) bib = new String[]{ null };
      for ( String bibcode: bib ) {
        // if ( bibcode == null || bibcode.isEmpty() ) continue;
        out.println( "<div>" ); 
        out.println( "<button type=\"button\" class=\"but\" onclick=\"this.parentNode.remove(); return false\">-</button>" ); 
        out.println( "<select name=\"bibcode\">" ); 
        seltext( pageContext, bibcode );
        out.println( "</select>" );
        out.println( "</div>" ); 
        done = true;
      }
      %>
      </fieldset>
      <label>Taille du contexte <input size="5" name="context" value="<%=context%>"/></label>
      <label>Pas <input size="5" name="step" value="<%=step%>"/></label>
      <button>▶</button>
    </form>
      <%
      ArrayList<String> texts = new ArrayList<String>();
      ArrayList<String> labels = new ArrayList<String>();
      for ( String bibcode: bib ) {
        if ( bibcode == null || bibcode.isEmpty() ) continue;
        String text = text( pageContext, bibcode );
        if ( text == null ) {
          out.println( "<p>Le texte "+bibcode+" n’est pas disponible sur ce serveur.</p>");
          continue;
        }
        texts.add( text );
        String[] cells = catalog.get( bibcode );
        if ( cells[1] != null && !cells[1].isEmpty() ) labels.add( cells[1]+". "+cells[2] );
        else labels.add( cells[2] );
      }
   // Boucler sur le texte
      if ( texts.size() > 0 ) {  
      %>
    <div id="chart" class="dygraph"></div>
    <script type="text/javascript">
    g = new Dygraph(
      document.getElementById("chart"),
      [
      <% 
      HashSet<String> dic = new HashSet<String>();
        DecimalFormat df = new DecimalFormat("#.######", DecimalFormatSymbols.getInstance(Locale.US ));
        // textes multiples
        TermRoller[] wheels = new TermRoller[ texts.size() ];
        Occ[] occs = new Occ[ texts.size() ];
        Tokenizer[] toks = new Tokenizer[ texts.size() ];
        for ( int i = 0; i < texts.size(); i++ ) {
          toks[i] = new Tokenizer( texts.get(i) );
          occs[i] = new Occ();
          wheels[i] = new TermRoller( -context-1, 0 );
        }
        int wn = 0;
        List<Integer> anns = new ArrayList<Integer>();
        boolean stop = false;
        while ( !stop ) {
          stop = true;
          wn++;
          for ( int i = 0; i < toks.length; i++ ) {
            if ( toks[i] == null ) continue;
            if ( !toks[i].word( occs[i] ) ) { // texte fini
              toks[i] = null;
              continue;
            }
            stop = false;
            // if( occ.orth().equals("§") ) anns.add( ((wn/step)+1)*step );
            if ( occs[i].tag().isPun() ) continue;
            wheels[i].push( occs[i].orth() );
          }
          if (wn < context ) continue;
          if ( wn % step != 0 ) continue;
          out.print("        ["+wn );
          for ( int i = 0; i < toks.length; i++ ) {
            if ( toks[i] == null ) {
              out.print( ", null ");
              continue;
            }
            dic.clear();
            // sortir le dictionnaire
            for ( Term term: wheels[i] ) {
              if ( !dic.contains( term ) ) dic.add( term.toString() );
            }
            int forms = dic.size();
            out.print( ", "+df.format( 100.0*forms / context ));
          }
          out.println("]," );
        }
      
      /*
        Tokenizer toks1 = new Tokenizer( t1 );
        Tokenizer toks2 = new Tokenizer( t2 );
        Occ occ1 = new Occ();
        Occ occ2 = new Occ();
        int step = 5000;
        DicFreq dic1=new DicFreq();
        DicFreq dic2=new DicFreq();
        long occs = 0;
        while  ( true ) {
          if ( dic1 != null ) {
            if ( toks1.word( occ1 ) ) {
              if ( occ1.tag().isPun() ) continue;
              else dic1.add( occ1.orth() );
            }
            else {
              dic1 = null;
              if ( dic2 == null ) break;
            }
          }
          if ( dic2 != null ) {
            if ( toks2.word( occ2 ) ) {
              if ( occ2.tag().isPun() ) continue;
              else dic2.add( occ2.orth() );
            }
            else {
              dic2 = null;
              if ( dic1 == null ) break;
            }
          }
          occs++;
          if ( ( occs % step ) != 0 ) continue; // passer au pas suivant
          out.print("        ["+occs );
          double ratio = hat( dic1, dicsize);
          if ( ratio == 0 ) out.print( ", null");
          else out.print( ", "+df.format( 100.0*ratio ));
          ratio = hat( dic2, dicsize);
          if ( ratio == 0 ) out.print( ", null");
          else out.print( ", "+df.format( 100.0*ratio ));
          out.println("],");
        }
          */
      %>
      ],
      {
        title : "Richesse du vocabulaire, variations",
        titleHeight: 35,
        labels: [ "Index" <% for ( String label: labels) { out.print( ", \""+label+"\"" ); } %> ],
        legend: "always",
        labelsSeparateLines: "true",
        ylabel: "% formes/occurrences",
        labelsKMB: true,
        xlabel: "Nombre d’occurrences",
        showRoller: true,
        rollPeriod: <%= smooth %>,
        // logscale: true,
        series: {
        <% 
String[] colors = { 
  "rgba( 255, 0, 0, 0.5 )", 
  "rgba( 0, 0, 128, 0.5 )", 
  "rgba( 0, 128, 0, 0.5 )", 
  "rgba( 255, 128, 0, 0.5 )", 
  "rgba( 0, 192, 192, 0.5 )", 
  "rgba( 128, 0, 0, 0.5 )", 
  "rgba( 192, 0, 192, 0.5 )", 
};
for ( int i = 0; i < labels.size() ; i++ ) {
  out.println( "\""+labels.get( i ) + "\":{" );
  String color = colors[ i % colors.length ];
  out.println( "  color: \""+color+"\"," );
  out.println( "  strokeWidth: 4," );
  out.println( "}," );
  
}
        %>
        },
        axes: {
          x: {
            gridLineWidth: 0.5,
            drawGrid: true,
            gridLineColor: "rgba( 192, 192, 192, 1 )",
            independentTicks: true,
          },
          y: {
            independentTicks: true,
            drawGrid: true,
            gridLineColor: "rgba( 192, 192, 192, 1 )",
            gridLineWidth: 0.5,
          },
          y2: {
            independentTicks: true,
            drawGrid: false,
            gridLineColor: "rgba( 128, 128, 128, 0.3)",
            gridLineWidth: 2,
            gridLinePattern: [4,4],
          },
        },
      }
    );
    g.ready(function() {
      g.setAnnotations([
    <%
    if ( anns.size() <= 50 ) {
      for ( int n : anns ) {
        out.println( "{ series: \"Texte\", x:"+n+", shortText: \"Chapitre\", width: \"\", height: \"\", cssClass: \"ann\", }," );
      }
    }

    %>
      ]);
    });
    </script>
    <% } %>
    <div class="text">
      <p>
La richesse du “vocabulaire” se calcule généralement par le rapport entre un nombre de formes différentes 
(fléchies, lemmatisées…) et un nombre d’occurrences. 
En anglais, ce rapport est connu sous le nom TTR  (<i>type token ratio</i>).
Ce rapport varie selon les genres textuels.
Le vocabulaire du droit est par exemple spécialement restreint, pour limiter les équivoques, 
la loi varie donc moins que la littérature.
Une autre variable modifie beaucoup ce rapport, la taille d’un texte.
Quel que soit le corpus, il a été observé que plus un texte est long, plus on réutilise les mêmes mots
(le dictionnaire est fini), et donc la richesse lexicale diminue, du moins, à échelle globale.
Ce formulaire permet de définir une largeur de contexte, en nombre de mots, sur lequel calculer
le rapport formes / occurrences, et de faire glisser cette fenêtre sur un texte.
Une fenêtre de 1000 mots est souvent utilisée pour obtenir une mesure standardisée (STTR).
10 000 mots est une largeur plus commode pour comparer plusieurs textes et observer leurs variations,
car la richesse lexicale varie selon par exemple les romans d’un même auteur, voire les chapitres.
      </p>
    </div>
  </body>
 </html>
      
     