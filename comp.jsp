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
java.util.Scanner,

alix.util.Char,
alix.util.CompDic,
alix.util.CompDic.Balance,
alix.util.TermDic,
alix.fr.Tag,
alix.fr.Occ,
alix.fr.Tokenizer,
alix.fr.Lexik,
alix.fr.Lexentry
"%>
<%!
public static final String[] _FILTER = new String[] {  };
// "aller", "bientôt", "devoir", "demander", "donner", "faire", "falloir", "paraître", "pouvoir", "prendre", "savoir", "venir", "voir", "vouloir"
public static final HashSet<String> FILTER = new HashSet<String>(Arrays.asList(_FILTER));
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
}

%>
<%
long time;
DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.ENGLISH);
DecimalFormat mega = new DecimalFormat("###,###");
DecimalFormat dec1 = new DecimalFormat("###,###.0");
%>
<%@include file="common.jsp" %>
<!DOCTYPE html>
<html lang="fr">
  <head>
    <meta charset="UTF-8">
    <title>Comparateur de fréquences lexicales</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
  </head>
  <body>
    <%@include file="menu.jsp" %>
  <%
  float qfilter = 1.5f;
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
  String text1 = request.getParameter( "text1" );
  String text2 = request.getParameter( "text2" );
  String ref1 = request.getParameter( "ref1" );
  String ref2 = request.getParameter( "ref2" );
  if ( text1==null && ref1==null && text2==null && ref2==null ) {
    ref1="moliere_hommes";
    ref2="moliere_femmes";
    qfilter = 1.1f;
  }
  if ( text1==null ) text1="";
  if ( text2==null ) text2="";
  final String selected = " selected=\"selected\"";
  String sel;

  String[] cells;
  if ( !text1.isEmpty()  ) {
    dic1 = parse( text1 );
    ltitle = text1.substring( 0, Math.min( 30, text1.length() ) );
  }
  else if ( ref1 != null) {
    dic1 = dic( pageContext, ref1 );
    if ( dic1 != null) {
      cells = catalog.get( ref1 );
      ltitle = (cells[1]+". "+cells[2]);
    }
  }
  if ( !text2.isEmpty()  ) {
    dic2 = parse( text2 );
    rtitle = text2.substring( 0, Math.min( 30, text2.length() ) );
  }
  else if ( ref2 != null) {
    dic2 = dic( pageContext, ref2 );
    if ( dic2 != null) {
      cells = catalog.get( ref2 );
      rtitle = (cells[1]+". "+cells[2]);
    }
  }
  
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
    
    <form id="seltext" name="seltext" action="#seltext" style="width: 100%; text-align: center; z-index: 2; position: relative; clear: both; " 
    method="<%=(text1.isEmpty() && text2.isEmpty())?"get":"post" %>">
      <table>
        <tr>
          <td>
      <textarea name="text1" style="width: 100%; height: 10em;" placeholder="Copier/coller un texte"
        onblur="this.form.method = 'post'; this.form.action = '?' "
        onclick="this.select()"
      ><%=text1%></textarea>
      ou <select name="ref1" onchange="this.form.text1.value = ''; ">
        <% seltext( pageContext, ref1 ); %>
      </select>      
          </td>
          <td align="center">
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
      <br/>
      <label title="Filtrer les mots selon une catégorie grammaticale">
      Filtrer
        <select name="tag">
        <% String tag= request.getParameter( "tag" ); %>
          <option value="">Catégorie ?</option>
          <option value="SUB" <%=("SUB".equals( tag ))?" selected":"" %>>Substantifs</option>
          <option value="ADJ" <%=("ADJ".equals( tag ))?" selected":"" %>>Adjectifs</option>
          <option value="VERB" <%=("VERB".equals( tag ))?" selected":"" %>>Verbes</option>
        </select>
      </label>
      <br/>
      <button type="submit">Comparer</button>
          </td>
          <td>
      <textarea name="text2" style="width: 100%; height: 10em;" placeholder="Copier/coller un texte"
        onblur="this.form.method = 'post'; this.form.action = '?' "
        onclick="this.select()"
      ><%=text2%></textarea>
      ou <select name="ref2" onchange="this.form.text2.value = '';">
        <% seltext( pageContext, ref2 );  %>
      </select>
          </td>
        </tr>
      </table>
    </form>
<%

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
if ( ref1 != null && dic1 == null ) out.println( "<p>"+ref1+": texte inconnu de cette base.</p>" );
if ( ref2 != null && dic2 == null ) out.println( "<p>"+ref2+": texte inconnu de cette base.</p>" );
// la vue de comparaison
if ( dic1 != null && dic2 != null ) {
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
    if ( "SUB".equals( tag ) && mot.tag != Tag.SUB ) continue;
    if ( "ADJ".equals( tag ) && mot.tag != Tag.ADJ ) continue;
    if ( "VERB".equals( tag ) && mot.tag != Tag.VERB ) continue;
    // filtrer les mots vides au centre
    if ( Math.max(mot.freq1, mot.freq2)/Math.min(mot.freq1, mot.freq2) < qfilter ) {
      if ( Lexik.isStop( mot.term ) ) {
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
}
      %>
      </section>
    </article>
  </body>
</html>
