<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.IOException,
java.io.BufferedReader,
java.nio.charset.StandardCharsets,
java.nio.file.Files,
java.nio.file.Path,
java.nio.file.Paths,
java.text.DecimalFormat,
java.util.Arrays,
java.util.LinkedHashMap,

site.oeuvres.util.Char,
site.oeuvres.util.TermDic,
site.oeuvres.fr.Tag,
site.oeuvres.fr.Occ,
site.oeuvres.fr.Tokenizer,
site.oeuvres.fr.Lexik,
site.oeuvres.fr.LexikEntry
"%>
<%!static String[][] cat = {
  // new String[] {"11000", "apollinaire_11000-verges.xml", "Apollinaire", "Les Onze mille verges"},
  new String[] {"alcools", "apollinaire_alcools.xml", "Apollinaire", "Alcools"},
  // new String[] {"jdj", "apollinaire_exploits-jeune-don-juan.xml", "Apollinaire", "Les Exploits d’un jeune Don Juan"},
  // new String[] {"3dj", "apollinaire_trois-don-juan.xml", "Apollinaire", "Trois Don Juan"},
  // new String[] {"cleves", "la-fayette_princesse-cleves.xml", "Madame de La Fayette", "La Princesse de Clèves"},
  new String[] {"illusions", "balzac_illusions-perdues.xml", "Balzac", "Les Illusions perdues"},
  new String[] {"fleurs", "baudelaire_fleurs.xml", "Baudelaire", "Les Fleurs du Mal"},
  new String[] {"cahusac", "cahusac_encyclopedie.txt", "Cahusac, Louis de", "Articles de l’Encyclopédie"},
  new String[] {"corneillep", "corneillep.txt", "Corneille, Pierre", "Théâtre"},
  // new String[] {"corneillet", "corneillet.txt", "Corneille, Thomas", "Théâtre"},
  new String[] {"dumas", "dumas.txt", "Dumas", "Romans"},
  new String[] {"flaubert_bovary", "flaubert_madame-bovary.xml", "Flaubert", "Madame Bovary"},
  new String[] {"moliere", "moliere.txt", "Molière", "Théâtre"},
  new String[] {"proust_recherche", "proust_recherche.xml", "Proust", "À la recherche du temps perdu"},
  new String[] {"racine", "racine.txt", "Racine", "Théâtre"},
  new String[] {"sade", "sade.txt", "Sade", "Récits"},
  new String[] {"stendhal", "stendhal.xml", "Stendhal", "Romans"},
  new String[] {"stendhal_journal", "stendhal_journal.txt", "Stendhal", "Journal et papiers"},
  new String[] {"zola", "zola.xml", "Zola", "Romans"},
  // new String[] {"bete", "zola_bete.xml", "Zola", "La Bête humaine"},
  // new String[] {"bilitis", "louys_bilitis.html", "Pierre Louÿs", "Les chansons de Bilitis"},
};
static String[][] vues = {
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
  new String[] { "gramlist", "Mots grammaticaux, % Frantext" },
  new String[] { "verblist", "Verbes fréquents % Frantext", "withlems" },
};


/**
 * Charger un texte en vecteur de cooccurrents
 */
public TermDic load( String file, boolean lem) throws IOException {
  Path path =  Paths.get( file );
  String text = new String( Files.readAllBytes( path ), StandardCharsets.UTF_8 );
  return parse( text, lem);
}
public TermDic parse( String text, boolean lem) throws IOException {
  TermDic dic = new TermDic();
  Tokenizer toks = new Tokenizer(text);
  Occ occ = new Occ();
  // String last;
  while ( toks.word( occ ) ) {
    if (lem) {
      dic.add( occ.lem );
    }
    else dic.add( occ.orth );
  }
  return dic;
}%>
<%
  request.setCharacterEncoding("UTF-8");
String context = application.getRealPath("/");



// global vars
DecimalFormat numdf = new DecimalFormat("# ###");
DecimalFormat decdf = new DecimalFormat("0.00");
DecimalFormat biasdf = new DecimalFormat("# %");
%>
<!DOCTYPE html>
<html>
  <head>
    <title>Fréquence différentielle</title>
    <link rel="stylesheet" type="text/css" href="http://svn.code.sf.net/p/obvil/code/theme/obvil.css" />
  </head>
  <style>
.bg-10 { background: rgba(255, 0, 0, 1) !important; color: #FFF; }
.bg-9 { background: rgba(255, 0, 0, 0.9) !important; color: #FFF; }
.bg-8 { background: rgba(255, 0, 0, 0.8) !important; color: #FFF; }
.bg-7 { background: rgba(255, 0, 0, 0.7) !important; }
.bg-6 { background: rgba(255, 0, 0, 0.6) !important; }
.bg-5 { background: rgba(255, 0, 0, 0.5) !important; }
.bg-4 { background: rgba(255, 0, 0, 0.4) !important; }
.bg-3 { background: rgba(255, 0, 0, 0.3) !important; }
.bg-2 { background: rgba(255, 0, 0, 0.2) !important; }
.bg-1 { background: rgba(255, 0, 0, 0.1) !important; color: grey;}
.bg0 { background: #FFFFFF !important; color: grey; }
.bg1 { background: rgba(0, 0, 192, 0.1) !important; color: grey; }
.bg2 { background: rgba(0, 0, 192, 0.2) !important; }
.bg3 { background: rgba(0, 0, 192, 0.3) !important; }
.bg4 { background: rgba(0, 0, 192, 0.4) !important; }
.bg5 { background: rgba(0, 0, 192, 0.5) !important; }
.bg6 { background: rgba(0, 0, 192, 0.6) !important; }
.bg7 { background: rgba(0, 0, 192, 0.7) !important; }
.bg8 { background: rgba(0, 0, 192, 0.8) !important; color: #FFF; }
.bg9 { background: rgba(0, 0, 192, 0.9) !important; color: #FFF; }
.bg10 { background: rgba(0, 0, 192, 1.0) !important; color: #FFF; }
  </style>
  <body>
    <article id="article">
    <h1><a href=".">Alix</a> : différentes fréquences lexicales</h1>
      <%
        String text = request.getParameter( "text" );
        if ( text==null ) text="";
      %>
    <form style="position: fixed; float: left; width: 30em; " onsubmit="if (!this.text.value) return true; this.method = 'post'; this.action='?'; " method="get">
      <select name="bib" onchange="this.form.text.value = ''; this.method = 'GET';  this.form.submit()">
      <%
        String bib = request.getParameter("bib");
        if ( !"".equals( text ) ) bib = null;
        String selected = "";
        if ( bib == null ) selected = " selected=\"selected\"";
        out.print("<option value=\"\" disabled=\"disabled\" hidden=\"hidden\""+selected+">Choisir un texte…</option>");

        for ( int i = 0; i < cat.length; i++) {
          selected = "";
          if ( cat[i][0].equals( bib ) ) selected = " selected=\"selected\"";
          out.print("<option value=\""+cat[i][0]+"\""+selected+">"+cat[i][2]+". "+cat[i][3]+"</option>");
        }
      %>
      </select>
      <br/>
      <select name="vue" onchange="this.form.onsubmit(); this.form.submit()">
      <%
        String vue = request.getParameter( "vue" );
        selected = "";
        if ( vue == null ) selected = " selected=\"selected\"";
        out.print("<option value=\"\" disabled=\"disabled\" hidden=\"hidden\""+selected+">Choisir une liste de mots…</option>");
        String vuelabel = null;
        boolean vuelem = false;
        for ( int i = 0; i < vues.length; i++) {
          selected = "";
          if ( vues[i][0].equals( vue ) ) {
            selected = " selected=\"selected\"";
            vuelabel = vues[i][1];
            if ( vues[i].length > 2 && vues[i][2] != null ) vuelem = true;
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
      <button type="submit">Envoyer</button>
    </form>
    <div style="margin-left: 31em; ">
<%
  String[] bibl = null; // the current text
int index = 0;
while ( index < cat.length) {
  if (cat[index][0].equals( bib ))
    break;
  index++;
}
// not found
if ( index < cat.length ) {
  bibl = cat[index];
}

long time = System.nanoTime();

TermDic dico = null;
// text direct
if ( !"".equals( text )) {
  if ( vuelem ) dico = parse( text, true);
  else dico = parse( text, false);
}
else if( bib != null ) {
  String att = bib;
  if ( vuelem ) att = bib+"L";
  dico = (TermDic)application.getAttribute( att );
  if ( dico == null ) {
    String filepath = context + "/textes/" + bibl[1];
    if ( vuelem ) dico = load( filepath, true);
    else dico = load( filepath, false);
    application.setAttribute( att, dico );
    out.println( "Dictionnaire construit en "+((System.nanoTime() - time) / 1000000) + " ms");
  }
}

if ( dico == null ) {
  if ( bib != null ) out.print( "<p>Le texte "+bib+" n’est pas disponible sur ce serveur.</p>\n");
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
  	    String w;
  	    LexikEntry entry;
  	    while ( ( w = br.readLine() ) != null) {
  	  if ( w == null ) continue;
  	  if ( "".equals( w ) ) continue;
  	  if ( w.startsWith( "##" ) ) break;
  	  n++;
  	  out.print( "<tr>\n");
  	  // a label, not a word
  	  if ( w.charAt( 0 ) == '#' ) {
  	    out.print( "<th>"+n+"</th>\n" );
  	    out.print( "<th align=\"left\">"+w.substring( 1 ).trim()+"</th><th/><th/><th/>\n" );
  	    continue;
  	  }
  	  out.print( "<td align=\"right\">"+n+"</td>\n" );
  	  out.print( "<td>"+w+"</td>\n" );
  	  count = dico.count( w );
  	  if (count != 0) out.print( "<td align=\"right\">"+count+"</td>\n" );
  	  else out.print( "<td/>");
  	  entry = Lexik.entry( w );
  	  if ( vuelem ) {
  	    if ( entry != null ) franfreq = entry.lemfreq ;
  	    else franfreq = 0;
  	  } else {
  	    if ( entry != null ) franfreq = entry.orthfreq ;
  	    else franfreq = 0;
  	  }
  	  myfreq = 1.0*dico.count( w )*1000000/occs;
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
      int limit = 100;
      int n = 1;
      LexikEntry entry;

      // with no cache, 47ms on Dumas, seems OK
      time = System.nanoTime();
      String[] words = dico.byCount( 5000 );
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
          if ( "adj".equals( vue ) || "adv".equals( vue ) || "lem".equals( vue ) || "sub".equals( vue ) || "verb".equals( vue ) || "wordbias".equals( vue ) ) {
              out.print("<th title=\"Effectif par million d’occurrences\">Frantext</th>\n");
              out.print("<th title=\"0% = absent du texte, 50% = même fréquence dans le texte et Frantext, 100% absent (ou presque) de Frantext\">% Frantext</th>\n");
            }
        %>
      </tr>
      <%
        // loop on text forms in
        for (int i = 0; i < size; i++) {
          float franfreq = 0;
          double myfreq = 0;
          double bias = 0;
          if ( words[i].isEmpty() ) continue;
          if ( "nostop".equals( vue ) ) {
            if (Lexik.isStop( words[i] )) continue;
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
          else if ( "sub".equals( vue ) || "verb".equals( vue ) || "adj".equals( vue ) || "adv".equals( vue ) ) {
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
          if ( franfreq > 0 ) {
            out.print( "<td align=\"right\">"+decdf.format(franfreq)+"</td>\n" );
            String bg = "bg" + Math.round( 10.0 * (2 * bias - 1) );
            out.print( "<td align=\"right\" class=\""+bg+"\">"+ biasdf.format( bias )+"</td>\n" );
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
    </div>
    </article>
    <script src="Sortable.js">//</script>
  </body>
</html>
