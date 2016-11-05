<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.IOException,
java.io.BufferedReader,
java.nio.charset.StandardCharsets,
java.nio.file.Files,
java.nio.file.Path,
java.nio.file.Paths,
java.text.DecimalFormat,
java.text.DecimalFormatSymbols,
java.util.Arrays,
java.util.HashSet,
java.util.Locale,
java.util.List,

site.oeuvres.util.Char,
site.oeuvres.util.CompDic,
site.oeuvres.util.CompDic.Balance,
site.oeuvres.util.TermDic,site.oeuvres.fr.Tag,site.oeuvres.fr.Occ,site.oeuvres.fr.Tokenizer,site.oeuvres.fr.Lexik,site.oeuvres.fr.LexikEntry"%>
<%!/** liste de textes */
static String[][] catalog = {
  new String[] {"apollinaire_poesie", "apollinaire_poesie.xml", "Apollinaire", "Poésie"},
  new String[] {"baudelaire_fleurs", "baudelaire_fleurs.xml", "Baudelaire", "Les Fleurs de Mal"},
  new String[] {"corneillep", "corneillep.txt", "Corneille, Pierre", "Théâtre"},
  new String[] {"corneillep_femmes", "corneillep_femmes.txt", "Corneille, Pierre", "Femmes, répliques"},
  new String[] {"corneillep_hommes", "corneillep_hommes.txt", "Corneille, Pierre", "Hommes, répliques"},
  new String[] {"corneillet", "corneillet.txt", "Corneille, Thomas", "Théâtre"},
  new String[] {"dumas", "dumas.txt", "Dumas", "Romans"},
  new String[] {"la-fayette", "la-fayette_princesse-cleves.xml", "La Fayette", "La Princesse de Clèves"},
  new String[] {"moliere", "moliere.txt", "Molière", "Théâtre"},
  new String[] {"moliere_femmes", "moliere_femmes.txt", "Molière", "Femmes, répliques"},
  new String[] {"moliere_hommes", "moliere_hommes.txt", "Molière", "Hommes, répliques"},
  new String[] {"proust_recherche", "proust_recherche.xml", "Proust", "À la recherche du temps perdu"},
  new String[] {"racine", "racine.txt", "Racine", "Théâtre"},
  new String[] {"racine_femmes", "racine_femmes.txt", "Racine", "Femmes, répliques"},
  new String[] {"racine_hommes", "racine_hommes.txt", "Racine", "Hommes, répliques"},
  new String[] {"sade", "sade.txt", "Sade", "Récits"},
  new String[] {"stendhal", "stendhal.xml", "Stendhal", "Romans"},
  new String[] {"zola", "zola.xml", "Zola", "Romans"},
};
public static final String[] _FILTER = new String[] {  };
// "aller", "bientôt", "devoir", "demander", "donner", "faire", "falloir", "paraître", "pouvoir", "prendre", "savoir", "venir", "voir", "vouloir"
public static final HashSet<String> FILTER = new HashSet<String>(Arrays.asList(_FILTER));
/**
 * Récupérer un dictionnaire par identifiant
 */
public TermDic get( ServletContext application, final String code ) throws IOException 
{
  String att = "M"+code;
  TermDic dico = (TermDic)application.getAttribute( att );
  if ( dico != null ) return dico;
  // retrouver l’enregistrement
  int i = 0;
  String[] bibl = null;
  while ( i < catalog.length) {
    if (catalog[i][0].equals( code )) {
      bibl = catalog[i];
      break;
    }
    i++;
  }
  // texte inconnu
  if ( bibl == null ) return null;
  String home = application.getRealPath("/");
  String filepath = home + "/textes/" + bibl[1];
  Path path =  Paths.get( filepath );
  dico = parse( new String( Files.readAllBytes( path ), StandardCharsets.UTF_8 ) );
  application.setAttribute( att, dico );
  return dico;
}
/**
 * Charger un dictionnaire avec les mots d’un texte
 */
public TermDic parse( String text ) throws IOException {
  TermDic dic = new TermDic();
  Tokenizer toks = new Tokenizer(text);
  Occ occ = new Occ();
  short cat;
  while ( toks.word( occ ) ) {
    if ( occ.tag.isVerb() ) {
      dic.add( occ.lem );
    }
    else dic.add( occ.orth );
  }
  return dic;
}
/**
 *
 */
public float log ( double percent )
{
  int sign = 1;
  if ( percent < 50 ) sign = -1;
  percent = 1+9*Math.abs(percent - 50)/50;
  // 1.0 precision
  percent = Math.round(10* (50+sign*50* Math.log10( percent )))/10 ;
  return (float)percent;
}%>
<%
request.setCharacterEncoding("UTF-8");
long time;
DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.ENGLISH);
DecimalFormat mega = new DecimalFormat("###,###");
DecimalFormat dec1 = new DecimalFormat("###,###.0");

%>
<!DOCTYPE html>
<html>
  <head>
    <title>Comparateur de fréquences lexicales</title>
    <link rel="stylesheet" type="text/css" href="http://svn.code.sf.net/p/obvil/code/theme/obvil.css" />
    <style type="text/css">
html, body { height: 100%; background-color: #f3f2ec; }
article { height: 100%; margin-top:0; padding: 0 2em 0 2em; font-family: sans-serif;   }
select, button {font-size: 18px; font-family: sans-serif; }
textarea { border: none; }
section:after, section:before, form:after, form:before, .bar:after, .bar:before { content:" "; visibility: hidden; display: block; clear: both; height: 0; }

.board { color: rgba(0, 0, 0, 0.7); height: 80%; bottom: 0; font-size: 18px; text-align: center; position: relative; }
.board .l, .board .c, .board .r  { display: block; position: absolute; text-decoration: none; background-color: rgba(255, 255, 255, 0.5); padding: 0 1ex;  z-index: 2; }
.board .l { text-align: left;  border-left: 1px solid #F00; margin-right: auto; }
.board .c { text-align: center; transform: translate(-50%, 0); }
.board .r { text-align: right; border-right: 1px solid #F00; margin-left: auto; }

.rule { border-bottom: 1px solid #000000; position: sticky; top: 10px; width: 100%; clear: both; }
.rule .title { font-size: 25px; color: rgba( 255, 0, 0, 0.5 ); margin: 2em 1em; }
.rule .l, .rule .c, .rule .r { position: absolute; background: transparent; padding: 0 0.5ex; }
.rule .r { text-align: right; border-right: 1px solid #000; }
.rule .l { text-align: left;  border-left: 1px solid #000; }
.rule .c { text-align: center; }

.grid, .grid div { position: absolute; border-left: 1px dotted rgba( 0, 0, 0, 0.2); border-right: 1px dotted rgba( 0, 0, 0, 0.2); height: 100%; }

.bar { text-align:left; position: absolute; width: 100%; border-bottom: 1px solid rgba( 0, 0, 0, 0.2); z-index: 1; }



    </style>
  </head>
  <body>
  <%
  float qfilter = 2.0f;
  // différentes valeur pour la largeur du filtre
  float[] values= {1f, 1.1f, 1.2f, 1.5f, 2f, 3f, 5f, 10f};
  boolean seldone = false;
  String s = request.getParameter("qfilter");
  if ( s != null) {
    qfilter = Float.parseFloat( s );
  }
  if ( qfilter < 1 ) qfilter = 2.0f;
  String ltitle = "Texte gauche";
  String rtitle = "Texte droit";
  
  long laps;
  TermDic dic1 = null;
  TermDic dic2 = null;
  boolean go = false;
  %>
    <article>
    <h1><a href=".">Alix</a> : <a href="?">fréquences lexicales comparées</a></h1>
    <p>Ce tableau lexical présente les mots les plus fréquents de deux textes.
    Pour tester l’instrument, une petite collection est accessible avec les sélecteurs à droite et à gauche.
  	Il est aussi possible de soumettre ses propres textes (champ texte).
    
    Les fréquences sont relatives à la taille de chaque texte (nombre d’occurrences d’un mot 
    divisé par le nombre total d’occurrences dans le texte). 
    La proportion est donnée en “ppm” ou “parties par million”, nombre d’occurrences par millions de mots.
    La comparaison de textes très inégaux (> ×10) doit demander de la prudence d’interprétaion
    (ex: pour un roman, le nom du personnage principal sera très important, pour 20 romans, ils sont plus nombreux et moins visibles).
    Les mots apparaissent verticalement dans l’ordre de leur fréquence additionnée dans les deux textes.
    Ils sont positionnés latéralement selon qu’ils apparaissent plus dans un texte ou un autre.
    Un mot tout à gauche est présent uniquement dans le premier texte ; tout à droite, il n’est que dans le second texte ; au centre, 
    sa fréquence est égale dans les deux textes (sa fréquence relative, qui peut correspondre à des nombre différents d’occurrences). 
    La zone centrale montre les mots en commun, souvent significatifs d’un genre, ou d’un sujet partagé.
    Cette zone est filtrées des mots grammaticaux (de, le, la…), leurs variations sont faiblement significatives à cette échelle.
    Par contre, ils sont laissés dans les zones latérales, où ils peuvent donner des indications précieuses 
    sur des phénomènes syntaxiques (ponctuation, connecteurs, personnes…).
    La largeur de la zone centrale sans mot vide peut être modifiée par un sélecteur (×1, ×1.1, ×1.2…),
    afin de se concentrer sur les différences ou les ressemblances.
    </p>
    <%
    String text1 = request.getParameter( "text1" );
    String text2 = request.getParameter( "text2" );
    if ( text1==null ) text1="";
    if ( text2==null ) text2="";
    if ( !text1.isEmpty() && !text2.isEmpty() ) {
      dic1 = parse( text1 );
      dic2 = parse( text2 );
      ltitle = text1.substring( 0, 30 );
      rtitle = text2.substring( 0, 30 );
      go = true;
    }
    final String selected = " selected=\"selected\"";
    String sel;
    %>
    <form action="?" style="width: 100%; text-align: center; z-index: 2; clear: both; border: #FFFFFF solid 1px; padding: 0; margin: 0 0 1ex 0; " method="post">
      <textarea name="text1" style="width: 45%; height: 10em; float: left; "><%=text1%></textarea>
      <textarea name="text2" style="width: 45%; height: 10em; float: right"><%=text2%></textarea>
      <label title="Largeur de la zone centrale, sans mots grammaticaux">
        <select name="qfilter">
        <%
        for (float value: values) {
          out.print("<option value=\""+value+"\"");
          if ( !seldone && qfilter >= value ) {
            out.print( selected );
            seldone = false;
          }
          out.print("/>×"+value+"</option>");
        }
        %>
        </select>
      </label>
      <button type="submit" name="text">Comparer</button>
    </form>
    <form id="seltext" name="seltext" action="#seltext" style="width: 100%; text-align: center; z-index: 2; position: relative; clear: both; " method="get">
      <select name="ref1" style="float: left">
      <%
        String ref1 = request.getParameter("ref1");
        if ( !text1.isEmpty() ) ref1 = null;
        sel = "";
        if ( ref1 == null ) sel = selected;
        out.print("<option value=\"\" disabled=\"disabled\" hidden=\"hidden\""+sel+">Choisir un texte…</option>");
        for ( int i = 0; i < catalog.length; i++) {
          sel = "";
          if ( catalog[i][0].equals( ref1 ) ) {
            sel = selected;
            ltitle = catalog[i][2]+". "+catalog[i][3];
          }
          out.print("<option value=\""+catalog[i][0]+"\""+sel+">"+catalog[i][2]+". "+catalog[i][3]+"</option>");
        }
      %>
      </select>      
      <label title="Largeur de la zone centrale, sans mots grammaticaux">
        <select name="qfilter">
        <%
        for (float value: values) {
          out.print("<option value=\""+value+"\"");
          if ( !seldone && qfilter >= value ) {
            out.print( selected );
            seldone = false;
          }
          out.print("/>×"+value+"</option>");
        }
        %>
        </select>
      </label>
      <button type="submit">Comparer</button>
      <select name="ref2" style="float: right; text-align: right; ">
      <%
        String ref2 = request.getParameter("ref2");
        if ( !text2.isEmpty() ) ref2 = null;
        sel = "";
        if ( ref2 == null ) sel = selected;
        out.print("<option value=\"\" disabled=\"disabled\" hidden=\"hidden\""+sel+">Choisir un texte…</option>");
        for ( int i = 0; i < catalog.length; i++) {
          sel = "";
          if ( catalog[i][0].equals( ref2 ) ){
            sel = selected;
            rtitle = catalog[i][2]+". "+catalog[i][3];
          }
          out.print("<option value=\""+catalog[i][0]+"\""+sel+">"+catalog[i][2]+". "+catalog[i][3]+"</option>");
        }
      %>
      </select>
    </form>
<%
if ( ref1 != null && ref2 != null) {
  
  time = System.nanoTime();
  dic1 = get( application, ref1 );
  laps = ((System.nanoTime() - time) / 1000000);
  if ( laps > 1 ) out.println( "<p>"+ref1+": dictionnaire construit en "+ laps + " ms</p>");
  
  time = System.nanoTime();
  dic2 = get( application, ref2 );
  laps = ((System.nanoTime() - time) / 1000000);
  if ( laps > 1 ) out.println( "<p>"+ref2+": dictionnaire construit en "+ laps + " ms</p>");
  
  go = true;
}
if ( dic1 != null && dic2 != null ) {
%>
    <section>
      <div style="float:left; "><%= mega.format(dic1.occs()) %> <dfn title="Occurrences, taille du texte">occs.</dfn></div>
      <div style="float:right; "><%= mega.format(dic2.occs()) %> <dfn title="Occurrences, taille du texte">occs.</dfn></div>
    </section>
<% } %>
    <section class="board" id="board" >
    <div class="rule">
      <div class="l" style="left:<%=log(0)%>%">…</div>
      <div class="l" style="left:<%=log(9)%>%">×10</div>
      <div class="l" style="left:<%=log(16.66)%>%">×5</div>
      <div class="l" style="left:<%=log(25)%>%">×3</div>
      <div class="l" style="left:<%=log(33.3)%>%">×2</div>
      <div class="l" style="left:<%=log(40)%>%">×1,5</div>
      <div class="l" style="left:<%=log(45.45)%>%">×1,2</div>
      <div class="l" style="left:<%=log(47.62)%>%">×1,1</div>
      <div class="c" style="left:<%=log(50)%>%">=</div>
      <div class="r" style="right:<%=log(47.62)%>%">×1,1</div>
      <div class="r" style="right:<%=log(45.45)%>%">×1,2</div>
      <div class="r" style="right:<%=log(40)%>%">×1,5</div>
      <div class="r" style="right:<%=log(33.3)%>%">×2</div>
      <div class="r" style="right:<%=log(25)%>%">×3</div>
      <div class="r" style="right:<%=log(16.66)%>%">×5</div>
      <div class="r" style="right:<%=log(9)%>%">×10</div>
      <div class="r" style="right:<%=log(0)%>%">…</div>
      <div style="float: left" class="title"><%=ltitle %></div>
      <div style="float: right" class="title"><%=rtitle %></div>
    </div>
    <div class="grid" style="left: <%=log(9)%>%; right: <%=log(9)%>%;"></div>
    <div class="grid" style="left: <%=log(47.62)%>%; right: <%=log(47.62)%>%;"></div>
    <div class="grid" style="left: <%=log(25)%>%; right: <%=log(25)%>%;"></div>
    <%
    float gap =  Math.round(10* (50-100f/(qfilter + 1)))/10f ;
    %>
    <div class="center" style=" margin-left:<%=log(50-gap) %>%; margin-right:<%=log(50-gap) %>%; background: #FFFFFF;
        border-left: 4px rgba(255,0,0,0.3) solid; border-right: 4px rgba(255,0,0,0.3) solid; height: 100%; "> </div>  
<%
// la vue de comparaison
while ( go ) {
  if ( dic1 == null ) out.println( "<p>"+ref1+": texte inconnu de cette base.</p>" );
  if ( dic2 == null ) out.println( "<p>"+ref2+": texte inconnu de cette base.</p>" );
  if ( dic1 == null || dic2 == null ) break;
  CompDic comp = new CompDic();
  comp.add1( dic1 );
  comp.add2( dic2 );
  List<Balance> list = comp.sort();
  Balance mot;
  int size = list.size();
  int max = 1000;
  int n = 1;
  float top = 1;
  float xpos = 0;
  float last = 0;
  String cat = "c";
  String style = "";
  StringBuilder sb = new StringBuilder();
  for(int i = 0; i < size ; i++) {
    mot = list.get( i );
    // filtrer avant de calculer les positions
    if ( Math.max(mot.freq1, mot.freq2)/Math.min(mot.freq1, mot.freq2) < qfilter ) {
      if ( Lexik.isStop( mot.term ) ||  FILTER.contains(mot.term) ) {
        continue;
      }
    }
    // calculer l’endroit ou placet le mot
    // si le mot suivant n’est pas du même côté espacement plus petit
    
    xpos = log( 100.0*mot.freq2/(mot.freq1 + mot.freq2) );
    // côté gauche
    if ( xpos < 45 ) {
      cat = "l";
      style= " left:"+xpos+"%; ";
      xpos = -xpos;
    }
    // côté droit
    else if ( xpos > 55 ) {
      xpos = 100 - xpos;
      cat = "r";
      style= " right:"+(xpos)+"%; ";
    }
    else {
      cat = "c";
      style= " left:"+ xpos +"%; ";
    }
    double height = 0.8;
    if ( Math.abs(last - xpos) > 20 ) height = 0.2;
    last = xpos;
    
    
    top = (float)(Math.round( (top+height)*10 )/10.0);
    out.print( "<div title=\"" );
    out.print( mot.term+", " );
    // if (mot.freq1 > mot.freq2) out.print( " ×"+ dec1.format( mot.freq1/mot.freq2) +" ; " );
    // else if (mot.freq2 > mot.freq1) out.print( "/ "+ dec1.format( mot.freq2/mot.freq1) );
    out.print( mega.format( (int)mot.freq1) +" ppm"+" ("+mot.count1+" occs) "+", "+ (int)mot.freq2+" ppm"+" ("+mot.count2+" occs)");
    // if (mot.freq2 > mot.freq1) out.print( " ; ×"+ dec1.format( mot.freq2/mot.freq1) );
    // else if (mot.freq1 > mot.freq2) out.print( "/ "+ dec1.format( mot.freq1/mot.freq2) );
    out.println( "\" class=\""+cat+"\" style=\" top:"+top+"em; "+style+"\">"+mot.term+"</div>" );
    if ( (n % 25) == 0 ) {
      out.println("<div class=\"bar\" style=\"top:"+top+"em; \">");
      out.println(n);
      out.println("</div>");
    }
    n++;
    if ( n > max ) break;
  }
  // css hack to extend container
  out.print( "<style> #board { height: "+top+"em; }</style>");
  break;
}
      %>
      </section>
    </article>
  </body>
</html>
