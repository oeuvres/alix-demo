<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="

alix.util.Char,
alix.util.IntRoller,
alix.util.Phrase,
alix.util.PhraseDic,
alix.util.TermDic,
alix.fr.Tag,
alix.fr.Occ,
alix.fr.Tokenizer,
alix.fr.Lexik,
alix.fr.WordEntry

"%>
<%@include file="common.jsp" %>
<%
String bibcode = request.getParameter("bibcode");
String text = request.getParameter("text");
if ( text == null ) text = "";
int gramwidth = 3;
try { gramwidth = Integer.parseInt( request.getParameter("gramwidth")); }
catch (Exception e) {}
if ( gramwidth < 2 || gramwidth > 5) gramwidth = 3;
boolean locs = false;
if ( request.getParameter("locs") != null && !request.getParameter("locs").isEmpty(  )) locs = true;

%>
<!DOCTYPE html>
<html>
  <head>
    <title>Collocations</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
  </head>
  <body>
    <article id="article"">
      <h1><a href=".">Alix</a> : collocations (locutions et cooccurrences fréquentes)</h1>
      <form onsubmit="if (!this.text.value) return true; this.method = 'post'; this.action='?'; " method="get">
        <select name="bibcode" onchange="this.form.text.value = ''; this.method = 'GET';  this.form.submit()">
        <%
          if ( !"".equals( text ) ) bibcode = null;
          seltext( pageContext, bibcode );
        %>
        </select>
        <label>
          <select name="gramwidth" onchange="this.form.submit()">
        <%
        int[] values = { 2, 3, 4, 5 };
        int lim = values.length;
        String selected="";
        boolean seldone = false;
        for ( int i=0; i < lim; i++ ) {
          if ( !seldone && values[i] == gramwidth) {
            selected=" selected=\"selected\"";
            seldone = true;
          }
          out.println("<option"+selected+" value=\""+values[i]+"\">"+ values[i] +"</option>");
          selected = "";
        }

        %>
          </select>
          mots pleins
        </label>
        <label>
          <input type="checkbox" name="locs" <% if (locs) out.print(" checked=\"checked\""); %>/>
          Dictionnaire de locutions
        </label>
        <br/>
        <textarea name="text" style="width: 100%; height: 10em; "><%=text%></textarea>
        <br/>
        <button type="submit">Envoyer</button>
      </form>
      <%
      if ( text == null || text.isEmpty() ) text = text( pageContext, bibcode );
      if (text!= null && !text.isEmpty()) {  
        
        Phrase key = new Phrase( gramwidth, false ); // collocation key (series or bag)
        IntRoller gram = new IntRoller(0, gramwidth - 1); // collocation wheel
        IntRoller wordmarks = new IntRoller(0, gramwidth - 1); // positions of words recorded in the collocation key
        
        TermDic dic = new TermDic();
        PhraseDic phrases = new PhraseDic();
        
        int NAME = dic.add( "NOM" );
        int NUM = dic.add( "NUM" );
        BufferedReader buf = new BufferedReader(
          new InputStreamReader( Lexik.class.getResourceAsStream(  "dic/stop.csv" ), StandardCharsets.UTF_8 )
        );
        String l;
        // define a "sense level" in the dictionary, by inserting a stoplist at first
        int senselevel = -1;
        while ((l = buf.readLine()) != null) {
          int code = dic.add( l.trim() );
          if ( code > senselevel ) senselevel = code;
        }
        buf.close();
        // add some more words to the stoplits
        for (String w: new String[]{
             "chère", "dire", "dis", "dit", "jeune", "jeunes", "yeux"
        }) {
          int code = dic.add( w );
          if ( code > senselevel ) senselevel = code;
        }


        IntRoller wordflow = new IntRoller(15, 0);
        int code;
        int exit = 1000;
        StringBuffer label = new StringBuffer();
        Occ occ = new Occ(); // pointer on current occurrence in the tokenizer flow
        Tokenizer toks = new Tokenizer( text );
        int occs = 0;
        while(true) {
          if ( locs ) {
            occ = toks.word();
            if (occ == null ) break;
          }
          else {
            if ( ! toks.token(occ) ) break;
          }
          occs++;
          // clear after sentences
          if ( occ.tag().equals( Tag.PUNsent )) {
            wordflow.clear();
            gram.clear();
            wordmarks.clear();
            continue;
          }
          
          if (occ.tag().pun()) continue; // do not record punctuation
          else if ( occ.tag().name() ) code = NAME; // simplify names
          else if ( occ.tag().num() ) code = NUM; // simplify names
          else if ( occ.tag().verb() ) code = dic.add( occ.lem() );
          else code = dic.add( occ.orth() );
          // clear to avoid repetitions 
          // « Voulez vous sortir, grand pied de grue, grand pied de grue, grand pied de grue »
          if ( code == wordflow.first()) {
            wordflow.clear();
            gram.clear();
            wordmarks.clear();
            continue;
          }

          wordflow.push( code ); // add this token to the word flow
          wordmarks.dec(); // decrement positions of the recorded plain words
          if ( wordflow.get( 0 ) <= senselevel ) continue; // do not record empty words
          wordmarks.push( 0 ); // record a new position of full word
          gram.push( wordflow.get( 0 ) ); // store a signficant word as a collocation key
          if ( gram.get( 0 ) == 0 ) continue; // the collocation key is not complete
          
          key.set( gram ); // transfer the collocation wheel to a phrase key
          int count = phrases.inc( key );
          // new value, add a label to the collocation
          if ( count == 1 ) {
            label.setLength( 0 );
            for ( int i = wordmarks.get( 0 ); i <= 0 ; i++) {
              label.append( dic.term( wordflow.get( i )) );
              if ( i != 0 && label.charAt( label.length()-1 ) != '\'' ) label.append( " " );
            }
            // System.out.println( label );
            phrases.label( key, label.toString() );
          }
          // if ( --exit < 0 ) System.exit( 1 );
        }
        out.print( "<p>"+ppmdf.format(occs) +" occurrences, "
        + ppmdf.format(phrases.occs()) +" ngrams collectés, "
        + ppmdf.format(phrases.size())+" ngrams différents.</p>\n");
        phrases.html( out, 1000, dic );
      }
      %>
    </article>
  </body>
</html>
  