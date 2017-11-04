<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%!static final int ORTH=0;
static final int LEM=1;
static final int POS=2;

static String[][] vues = {
  new String[] { "tokens", "Graphies" },
  new String[] { "nostop", "Graphies filtrées" },
  new String[] { "lem", "Lemmes sans mots vides", "withlems" },
  new String[] { "sub", "Substantifs" },
  new String[] { "adj", "Adjectifs lemmatisés", "withlems" },
  new String[] { "verb", "Verbes lemmatisés", "withlems" },
  new String[] { "adv", "Adverbes" },
  new String[] { "name", "Noms propres" },
  // new String[] { "pos", "Proportions des catégories de mots" },
  new String[] { "listgram", "% mots grammaticaux fréquents, frantext" },
  new String[] { "listverb", "% verbes fréquents, frantext", "withlems" },
  new String[] { "listadj", "% adjectifs fréquents, frantext", "withlems" },
};


public DicFreq dic( String text, int mode) throws IOException {
  DicFreq dic = new DicFreq();
  Tokenizer toks = new Tokenizer(text);
  Occ occ = new Occ();
  // String last;
  while ( toks.word( occ ) ) {
    if (mode == LEM) {
      dic.inc( occ.lem(), occ.tag().code(  ) );
    }
    else {
      dic.inc( occ.orth(), occ.tag().code(  ) );
    }
  }
  return dic;
}%>
<%
  // request parameters
String bibcode = request.getParameter("bibcode");
String vue = request.getParameter( "vue" );
String frantext = request.getParameter( "frantext" );
Float tlfratio = null;
if ( frantext != null ) {
  try { tlfratio = new Float( frantext ); }
  catch ( Exception e) {}
}

boolean vuelem = false;
String vuelabel = vues[0][1];
for ( int i = 0; i < vues.length; i++) {
  if ( vues[i][0].equals( vue ) ) {
    if ( vues[i].length > 2 && vues[i][2] != null ) vuelem = true;
    vuelabel = vues[i][1];
  }
}
%>
<%@include file="common.jsp" %>
<%
  DecimalFormat numdf = new DecimalFormat("# ###");
DecimalFormat biasdf = new DecimalFormat("#.00", frsyms);
String context = application.getRealPath("/");
%>
<!DOCTYPE html>
<html>
  <head>
    <title>Fréquence différentielle</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
  </head>
  <body>
    <%@include file="menu.jsp" %>
    <article id="article"">
    <h1><a href=".">Alix</a> : différentes fréquences lexicales</h1>
      <%
       String text = request.getParameter( "text" );
       if ( text==null ) text="";
       String[] cells = catalog.get( bibcode );
       String title = "";
       if ( cells == null);
       else if ( cells[1] != null && !cells[1].isEmpty() ) title = cells[1]+". "+cells[2];
       else title = cells[2];
      %>
    <section style=" float: left;  ">
<%
  String[] bibl = catalog.get( bibcode );
long time = System.nanoTime();
DicFreq dico = null;

// text direct
if ( !"".equals( text )) {
  if ( vuelem ) dico = dic( text, LEM);
  else dico = dic( text, ORTH);
}
else if( bibcode != null && bibl != null ) {
  String att = bibcode;
  if ( vuelem ) att = bibcode+"L";
  dico = (DicFreq)application.getAttribute( att );
  if ( dico == null ) {
    String xml = text( pageContext, bibcode );
    if ( vuelem ) dico = dic( xml, LEM);
    else dico = dic( xml, ORTH);
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
else if ( vue != null && vue.startsWith( "list" ) ) {
  Path listfile = Paths.get( context, vue+".txt" );
  long occs = dico.occs();
%>
    <table class="sortable scroll">
      <caption><%= bibl[1]%><%= (bibl[1].isEmpty())?"":", " %><i><%=bibl[2]%></i>,  <%=numdf.format( occs )%> mots (<%= vuelabel %>)</caption>
      <thead>
      <tr>
        <th title="Ordre d’exploration">Plan</th>
        <th title="Forme graphique">Graphie</th>
        <th title="Nombre d’occurrences dans le texte">Occs</th>
        <th title="Texte, effectif par million d’occurrences">Texte</th>
        <th title="Frantext, effectif par million d’occurrences">Frantext</th>
        <th title="">% Frantext</th>
      </tr>
      </thead>
      <tbody>
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
        LexEntry entry;
        while ( ( l = br.readLine() ) != null) {
          if ( l == null ) continue;
          if ( "".equals( l ) ) continue;
          if ( l.startsWith( "##" ) ) break;
          n++;
          out.print( "<tr>\n");
          // a label, not a word
          if ( l.charAt( 0 ) == '#' ) {
            out.print( "<th>"+n+"</th>\n" );
            // out.print( "<th style=\"text-align: left\" colspan=\"2\">"+l.substring( 1 ).trim()+"</th>\n" );
            out.print( "<th colspan=\"2\"></th>");
            out.print( "<th>Texte</th>" );
            out.print( "<th>Frantext</th>" );
            out.print( "<th>% Frantext</th>" );
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
          // comment est-ce possible ?
          if ( count < 0 ) count = 0;
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
          myfreq = 1.0*count*1000000/occs;
          bias =  myfreq  / (myfreq + franfreq);
          out.print( "<td align=\"right\">"+dfppm.format(myfreq)+" / M</td>\n" );
          out.print( "<td align=\"right\">"+dfppm.format(franfreq)+" / M</td>\n" );
          if ( franfreq == 0 ) {
            out.print( "<td></td>\n" );
          }
          else {
            String label;
            String bg = "bg" + Math.round( 10.0 * (2 * bias - 1) );
            if ( myfreq > franfreq) label = "x "+biasdf.format(myfreq/franfreq);
            else label = "/ "+biasdf.format(franfreq/myfreq);
            out.print( "<td align=\"right\" class=\""+bg+"\">"+ label+"</td>\n" );
          }
          out.print( "</tr>\n");
        }
      %>
      </tbody>
    </table>
    <%
      }
        else {
      long occs = dico.occs();
      int limit = 300;
      int n = 1;
      LexEntry entry;

      // with no cache, 47ms on Dumas, seems OK
      time = System.nanoTime();
      // String[] words = dico.byCount( -1 );
      // out.println( "Chargé en "+((System.nanoTime() - time) / 1000000) + " ms");
      // int size = words.length;
      String cat;
    %>
    <table class="sortable scroll">
      <caption><%= bibl[1]%><%= (bibl[1].isEmpty())?"":", " %><i><%=bibl[2]%></i>,  <%=numdf.format( occs )%> mots (<%= vuelabel %>)</caption>
      <thead>
      <tr>
        <th>N°</th>
        <th>Graphie</th>
        <th title="Nombre d’occurrences dans le texte">Occs</th>
        <%
          boolean tlfcol = false;
              if ( "tokens".equals( vue ) );
              else if ( "name".equals( vue ) ) out.print("<th>Catégorie</th>");
              else {
                  tlfcol = true;
                  out.print("<th title=\"Texte, effectif par million d’occurrences\">Texte</th>");
                  out.print("<th title=\"Frantext, effectif par million d’occurrences\">Frantext</th>");
                  out.print("<th title=\"\">% Frantext</th>\n");
                }
        %>
      </tr>
      </thead>
      <tbody>
      <%
        float franfreq = 0;
          double myfreq = 0;
          double bias = 0;
          String bg = "";
          String label;
          int count = 0;
          // loop on text forms in
          for ( Entry dicline: dico.byCount() ) {
            String word = dicline.label();
            // if ( dicline. ) continue;
            int tag = dicline.tag();
            count = dicline.count();
            if ( "tokens".equals( vue ) ) {
              out.print( "<tr>\n");
              out.print( "<td>"+n+"</td>\n" );
              out.print( "<td>"+word+"</td>\n" );
              out.print( "<td>"+count+"</td>\n" );
              out.print( "</tr>\n");
              n++;
              if (n > limit) break;
              continue;
            }
            if ( "name".equals( vue ) ) {
              if ( !Tag.isName( tag )) continue;
              /*
              if ( "pers".equals( vue ) && tag != Tag.NAMEpers && tag != Tag.NAMEpersf && tag != Tag.NAMEpersm ) continue;
              if ( "place".equals( vue ) && tag != Tag.NAMEplace ) continue;
              if ( "name".equals( vue ) && tag != Tag.NAME ) continue;
              */
              out.print( "<tr>\n");
              out.print( "<td>"+n+"</td>\n" );
              out.print( "<td>"+word+"</td>\n" );
              out.print( "<td>"+count+"</td>\n" );
              out.print( "<td>"+ Tag.label( tag ) +"</td>\n" );
              out.print( "</tr>\n");
              n++;
              if (n > limit) break;
              continue;
            }
            if ( "devoir".equals( word )) entry = Lexik.entry( "doit" );
            else entry = Lexik.entry( word );

            // filtrer les mots vides quand seuil frantext ?
            if ( "nostop".equals( vue ) || "lem".equals( vue ) ) {
              if ( tlfratio == null && Lexik.isStop( word )) continue;
              if ( tlfratio != null && ( Tag.isName( tag ) || Tag.isPun( tag ) || entry == null )) continue;
              if ( tlfratio != null && tlfratio < 2 && tlfratio > - 2 && Lexik.isStop( word )) continue;
            }
            if ( "sub".equals( vue ) && tag != Tag.SUB ) continue;
            if ( "verb".equals( vue ) && !Tag.isVerb( tag ) ) continue ;
            if ( "adj".equals( vue ) && tag != Tag.ADJ ) continue;
            if ( "adv".equals( vue ) && !Tag.isAdv( tag ) ) continue;

            if ( entry == null ) franfreq = 0;
            else if ( vuelem ) franfreq = entry.lemfreq;
            else franfreq = entry.orthfreq;
            myfreq = 1.0*dico.count( word )*1000000/occs;
            if ( tlfratio != null ) {
              if ( count < 2 ) continue;
              if ( franfreq == 0 ) continue;
              if ( tlfratio == 0) {
                if ( franfreq/myfreq > 2  || myfreq/franfreq > 2 ) continue;
              }
              else if ( tlfratio < 0) {
                if ( franfreq/myfreq < -tlfratio ) continue;
              }
              else if ( tlfratio > 0) {
                if ( myfreq/franfreq < tlfratio ) continue;
              }
            }

            bias =  myfreq / (myfreq + franfreq);
            out.print( "<tr>\n");
            out.print( "<td>"+n+"</td>\n" );
            out.print( "<td>"+word+"</td>\n" );
            out.print( "<td align=\"right\">"+count+"</td>\n" );
            out.print( "<td align=\"right\">"+dfppm.format(myfreq)+" / M</td>\n" );
            out.print( "<td align=\"right\">"+dfppm.format(franfreq)+" / M</td>\n" );
            if ( franfreq == 0 ) {
              bg = "";
              out.print( "<td></td>\n" );
            }
            else {
              bg = "bg" + Math.round( 10.0 * (2 * bias - 1) );
              if ( myfreq > franfreq) label = "x "+biasdf.format(myfreq/franfreq);
              else label = "/ "+biasdf.format(franfreq/myfreq);
              out.print( "<td align=\"right\" class=\""+bg+"\">"+ label+"</td>\n" );
            }
            out.print( "</tr>\n");
            n++;
            if (n > limit) break;
          }
      %>
      </tbody>
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
          for ( int i = 0; i < vues.length; i++) {
            selected = "";
            if ( vues[i][0].equals( vue ) ) {
              selected = " selected=\"selected\"";
            }
            out.print("<option value=\""+vues[i][0]+"\""+selected+">"+vues[i][1]+"</option>");
          }
      %>
      </select>
      <br/>
      <label>Seuil Frantext
        <select name="frantext" onchange="this.form.onsubmit(); this.form.submit()">
          <option/>
          <% tlfoptions ( pageContext, frantext ); %>
        </select>
      </label>
      <br/>
      <textarea name="text" style="width: 100%; height: 10em; "><%=text%></textarea>
      <br/>
      <button onclick="this.form.text.value='';" type="button">Effacer</button>
      <button type="submit" style="float: right">Envoyer</button>
    </form>
    </div>

    </article>
    <script src="lib/Sortable.js">//</script>
  </body>
</html>
