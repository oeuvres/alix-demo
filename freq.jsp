<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.IOException,
java.io.BufferedReader,
java.io.InputStream,
java.nio.charset.StandardCharsets,
java.nio.file.Files,
java.nio.file.Path,
java.nio.file.Paths,
java.text.DecimalFormat,
java.util.Arrays,
java.util.LinkedHashMap,
java.util.Scanner,

alix.util.Char,
alix.util.TermDic,
alix.fr.Tag,
alix.fr.Occ,
alix.fr.Tokenizer,
alix.fr.Lexik,
alix.fr.WordEntry"%>
<%!static String[][] vues = {
  new String[] { "tokens", "Graphies" },
  new String[] { "nostop", "Graphies sans mots vides" },
  // new String[] { "words", "Mots de la langue" },
  // new String[] { "wordbias", "Mots de la langue, % Frantext" },
  // new String[] { "lems", "Lemmes", "withlems" },
  // new String[] { "lemnostop", "Lemmes sans mots vides", "withlems" },
  new String[] { "lem", "Lemmes sans mots vides", "withlems" },
  new String[] { "sub", "Substantifs" },
  new String[] { "adj", "Adjectifs lemmatisés", "withlems" },
  new String[] { "verb", "Verbes lemmatisés", "withlems" },
  new String[] { "adv", "Adverbes" },
  new String[] { "name", "Noms propres" },
  new String[] { "gramlist", "Mots grammaticaux, % Frantext" },
  new String[] { "verblist", "Verbes fréquents % Frantext", "withlems" },
};

/**
 * Charger un texte en vecteur de cooccurrents
 */
public TermDic load( PageContext pageContext, String res, boolean lem) throws IOException {
  InputStream stream = pageContext.getServletContext().getResourceAsStream( res );
  if ( stream == null ) return null;
  Scanner sc = new Scanner( stream, "UTF-8" );
  sc.useDelimiter("\\A");
  String text = sc.next();
  sc.close();
  return parse( text, lem);
}

public TermDic parse( String text, boolean lem) throws IOException {
  TermDic dic = new TermDic();
  Tokenizer toks = new Tokenizer(text);
  Occ occ = new Occ();
  // String last;
  while ( toks.word( occ ) ) {
    if (lem) {
      dic.inc( occ.lem, occ.tag.code(  ) );
    }
    else {
      dic.inc( occ.orth, occ.tag.code(  ) );
    }
  }
  return dic;
}%>
<%
  request.setCharacterEncoding("UTF-8");
%>
<%
// request parameters
String bibcode = request.getParameter("bibcode");
String vue = request.getParameter( "vue" );
boolean vuelem = false;
for ( int i = 0; i < vues.length; i++) {
  if ( vues[i][0].equals( vue ) ) {
    if ( vues[i].length > 2 && vues[i][2] != null ) vuelem = true;
  }
}


// global vars
DecimalFormat numdf = new DecimalFormat("# ###");
DecimalFormat decdf = new DecimalFormat("0.00");
DecimalFormat biasdf = new DecimalFormat("# %");
String context = application.getRealPath("/");
%>
<%@include file="common.jsp" %>
<!DOCTYPE html>
<html>
  <head>
    <title>Fréquence différentielle</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
  </head>
  <body>
    <article id="article"">
    <h1><a href=".">Alix</a> : différentes fréquences lexicales</h1>
      <%
        String text = request.getParameter( "text" );
          if ( text==null ) text="";
      %>
    <section style=" float: left;  ">
<%
  String[] bibl = catalog.get(bibcode);

long time = System.nanoTime();

TermDic dico = null;

// text direct
if ( !"".equals( text )) {
  if ( vuelem ) dico = parse( text, true);
  else dico = parse( text, false);
}
else if( bibcode != null && bibl != null ) {
  String att = bibcode;
  if ( vuelem ) att = bibcode+"L";
  dico = (TermDic)application.getAttribute( att );
  if ( dico == null ) {
    if ( vuelem ) dico = load( pageContext, bibl[0], true);
    else dico = load( pageContext, bibl[0], false);
    if (dico != null ) {
  application.setAttribute( att, dico );
  out.println( "Dictionnaire construit en "+((System.nanoTime() - time) / 1000000) + " ms");
    }
    else {
  out.print( "<p>Le texte "+bibl[0]+" n’est pas disponible sur ce serveur.</p>\n");
    }
  }
}

if ( dico == null ) {
  if ( bibcode != null ) out.print( "<p>Le texte "+bibcode+" n’est pas disponible sur ce serveur.</p>\n");
}
else if ( "gramlist".equals( vue ) || "verblist".equals( vue ) ) {
  Path listfile = Paths.get( context, "/gram.txt" );
  if ( "verblist".equals( vue ) ) listfile = Paths.get( context, "/verbs.txt" );
  long occs = dico.occs();
%>
  	<table class="sortable">
      <caption>
      <%
        //       <caption> bibl[2], <i>bibl[3]</i>,  numdf.format( occs ) mots<br/> ( vuelabel )</caption>
      %>
      </caption>
      <tr>
        <th title="Ordre d’exploration">Plan</th>
        <th title="Forme graphique">Graphie</th>
        <th title="Effectif pour le texte">Texte</th>
        <th title="Effectif par million d’occurrences">Frantext</th>
        <th title="0 % absent du texte, 50 % même fréquence dans le texte et Frantext, 100 % absent (ou presque) de Frantext">% Frantext</th>
      </tr>
  	<%
  	  BufferedReader br = Files.newBufferedReader(  listfile, StandardCharsets.UTF_8 );
  	    int n = 0;
  	    int count;
  	    float franfreq = 0;
  	    double myfreq = 0;
  	    double bias = 0;
  	    String l;
        String word;
        String lem;
        int pos;
  	    WordEntry entry;
  	    while ( ( l = br.readLine() ) != null) {
  	  	  if ( l == null ) continue;
  	  	  if ( "".equals( l ) ) continue;
  	  	  if ( l.startsWith( "##" ) ) break;
  	  	  n++;
  	  	  out.print( "<tr>\n");
  	  	  // a label, not a word
  	  	  if ( l.charAt( 0 ) == '#' ) {
  	  	    out.print( "<th>"+n+"</th>\n" );
  	  	    out.print( "<th align=\"left\">"+l.substring( 1 ).trim()+"</th><th/><th/><th/>\n" );
  	  	    continue;
  	  	  }
          if ((pos=l.indexOf( ';' )) > -1) {
            lem = l.substring( 0, pos );
            word = l.substring( pos+1 );
          }
          else {
            lem =l;
            word = l;
          }
  	  	  out.print( "<td align=\"right\">"+n+"</td>\n" );
  	  	  out.print( "<td>"+lem+"</td>\n" );
  	  	  count = dico.count( lem );
  	  	  if (count != 0) out.print( "<td align=\"right\">"+count+"</td>\n" );
  	  	  else out.print( "<td/>");
  	  	  entry = Lexik.entry( word );
  	  	  if ( vuelem ) {
  	  	    if ( entry != null ) franfreq = entry.lemfreq ;
  	  	    else franfreq = 0;
  	  	  } else {
  	  	    if ( entry != null ) franfreq = entry.orthfreq ;
  	  	    else franfreq = 0;
  	  	  }
  	  	  myfreq = 1.0*dico.count( lem )*1000000/occs;
  	  	  bias =  myfreq  / (myfreq + franfreq);
  	  	  out.print( "<td align=\"right\">"+decdf.format(franfreq)+"</td>\n" );
  	  	  String bg = "bg" + Math.round( 10.0 * (2*bias - 1) );
  	  	  out.print( "<td align=\"right\" class=\""+bg+"\">"+ biasdf.format( bias )+"</td>\n" );

  	  	  out.print( "</tr>\n");
  	  		}
  	%>
  	</table>
    <%
      }
        else {
      long occs = dico.occs();
      int limit = 300;
      int n = 1;
      WordEntry entry;

      // with no cache, 47ms on Dumas, seems OK
      time = System.nanoTime();
      String[] words = dico.byCount( 10000 );
      // out.println( "Chargé en "+((System.nanoTime() - time) / 1000000) + " ms");
      int size = words.length;
      String cat;
    %>
    <table class="sortable">
      <%
        //       <caption>bibl[2], <i>bibl[3]</i>, numdf.format( occs ) mots<br/> ( vuelabel)</caption>
      %>
      <tr>
        <th>N°</th>
        <th>Graphie</th>
        <th>Occurrences</th>
        <%
          boolean frantext = false;
          if ( "adj".equals( vue ) 
              || "adv".equals( vue ) 
              || "lem".equals( vue ) 
              || "nostop".equals( vue ) 
              || "sub".equals( vue ) 
              || "verb".equals( vue ) 
              || "wordbias".equals( vue ) 
          ) {
              frantext = true;
              out.print("<th title=\"Effectif par million d’occurrences\">Frantext</th>\n");
              out.print("<th title=\"0% = absent du texte, 50% = même fréquence dans le texte et Frantext, 100% absent (ou presque) de Frantext\">% Frantext</th>\n");
            }
          if ( "name".equals( vue ) ) out.print("<th>Catégorie</th>");
        %>
      </tr>
      <%
        // loop on text forms in
        for (int i = 0; i < size; i++) {
          float franfreq = 0;
          double myfreq = 0;
          double bias = 0;
          String bg = "";
          if ( words[i].isEmpty() ) continue;
          if ( "nostop".equals( vue ) ) {
            if (Lexik.isStop( words[i] )) continue;
            entry = Lexik.entry(words[i] );
            if ( entry != null ) franfreq = entry.orthfreq;
            myfreq = 1.0*dico.count( words[i] )*1000000/occs;
            bias =  myfreq / (myfreq + franfreq);
          }
          else if ( "words".equals( vue )) {
            if (Lexik.isStop( words[i] )) continue;
            if ( Char.isUpperCase( words[i].charAt( 0 ) )) continue;
          }
          else if ( "lems".equals( vue )) {
            if ( Char.isPunctuation( words[i].charAt( 0 ) )) continue;
          }
          else if ( "lemnostop".equals( vue )) {
            if (Lexik.isStop( words[i] )) continue;
            if ( Char.isUpperCase( words[i].charAt( 0 ) )) continue;
          }
          else if ( "lem".equals( vue ) || "wordbias".equals( vue ) ) {
            if (Lexik.isStop( words[i] )) continue;
            // supprimer les noms propres ?
            if ( Char.isUpperCase( words[i].charAt( 0 ) )) continue;
            entry = Lexik.entry(words[i] );
            if ("lem".equals( vue )) {
              if ( entry != null ) franfreq = entry.lemfreq;
              else franfreq = 0;
            } else {
              if ( entry != null ) franfreq = entry.orthfreq;
              else franfreq = 0;
            }
            myfreq = 1.0*dico.count( words[i] )*1000000/occs;
            bias =  myfreq / (myfreq + franfreq);
            // if (bias < 0.33) continue;
          }
          else if ( "name".equals( vue ) ) {
            int tag = dico.tag( words[i] );
            if ( !Tag.isName( tag )) continue;
            /*
            if ( "pers".equals( vue ) && tag != Tag.NAMEpers && tag != Tag.NAMEpersf && tag != Tag.NAMEpersm ) continue;
            if ( "place".equals( vue ) && tag != Tag.NAMEplace ) continue;
            if ( "name".equals( vue ) && tag != Tag.NAME ) continue;
            */
            out.print( "<tr>\n");
            out.print( "<td>"+n+"</td>\n" );
            out.print( "<td>"+words[i]+"</td>\n" );
            out.print( "<td>"+dico.count( words[i] )+"</td>\n" );
            out.print( "<td>"+ Tag.label( dico.tag( words[i] ) )+"</td>\n" );
            out.print( "</tr>\n");
            n++;
            if (n > limit) break;
            continue;
          }
          else if ( "sub".equals( vue ) ||  "verb".equals( vue ) || "adj".equals( vue ) || "adv".equals( vue ) ) {
            if (Lexik.isStop( words[i] )) continue;
            // if ( Char.isUpperCase( words[i].charAt( 0 ) )) continue;
            entry = Lexik.entry(words[i] );
            if ( entry == null ) continue;
            if ( "verb".equals( vue ) && entry.tag.equals( Tag.VERB ) ) ;
            else if ( "adj".equals( vue ) &&  entry.tag.equals( Tag.ADJ ) );
            else if ( "sub".equals( vue ) && entry.tag.equals( Tag.SUB ) );
            else if ( "adv".equals( vue ) && entry.tag.equals( Tag.ADV ) );
            else continue;
            if ( vuelem ) franfreq = entry.lemfreq;
            else franfreq = entry.orthfreq;
            myfreq = 1.0*dico.count( words[i] )*1000000/occs;
            bias =  myfreq / ( myfreq + franfreq );
          }
          out.print( "<tr>\n");
          out.print( "<td>"+n+"</td>\n" );
          out.print( "<td>"+words[i]+"</td>\n" );
          out.print( "<td>"+dico.count( words[i] )+"</td>\n" );
          if ( frantext ) {
            out.print( "<td align=\"right\">"+decdf.format(franfreq)+"</td>\n" );
            if ( franfreq == 0 ) {
              bg = "";
              out.print( "<td></td>\n" );
            }
            else {
              bg = "bg" + Math.round( 10.0 * (2 * bias - 1) );
              out.print( "<td align=\"right\" class=\""+bg+"\">"+ biasdf.format( bias )+"</td>\n" );
            }
          }
          else if ( "adj".equals( vue ) || "adv".equals( vue ) || "lem".equals( vue ) || "sub".equals( vue ) || "verb".equals( vue ) || "wordbias".equals( vue ) ) {
              out.print( "<td/><td/>\n");
          }
          out.print( "</tr>\n");
          n++;
          if (n > limit) break;
        }
      %>
    </table>
    <%
}

    %>
    </section>
        <div style="float: left; ">
    <form id="form" style=" padding: 1rem; width: 30em; position: fixed; " onsubmit="if (!this.text.value) return true; this.method = 'post'; this.action='?'; " method="get">
      <select name="bibcode" onchange="this.form.text.value = ''; this.method = 'GET';  this.form.submit()">
      <%
          if ( !"".equals( text ) ) bibcode = null;
          seltext( pageContext, bibcode );
      %>
      </select>
      <br/>
      <select name="vue" onchange="this.form.onsubmit(); this.form.submit()">
      <%
          String selected = "";
          if ( vue == null ) selected = " selected=\"selected\"";
          out.print("<option value=\"\" disabled=\"disabled\" hidden=\"hidden\""+selected+">Choisir une liste de mots…</option>");
          String vuelabel = null;
          for ( int i = 0; i < vues.length; i++) {
            selected = "";
            if ( vues[i][0].equals( vue ) ) {
              selected = " selected=\"selected\"";
              vuelabel = vues[i][1];
            }
            out.print("<option value=\""+vues[i][0]+"\""+selected+">"+vues[i][1]+"</option>");
          }
          if ( vue == null ) {
            vue = vues[0][0];
            vuelabel = vues[0][1];
          }
      %>
      </select>
      <br/>
      <textarea name="text" style="width: 100%; height: 10em; "><%=text%></textarea>
      <br/>
      <button onclick="this.form.text.value='';" type="button">Effacer</button>
      <button type="submit" style="float: right">Envoyer</button>
    </form>
    </div>
    
    </article>
    <script>
    </script>
    <script src="Sortable.js">//</script>
  </body>
</html>
