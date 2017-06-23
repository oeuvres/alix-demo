<%@ page language="java" contentType="text/html; charset=UTF-8"
  pageEncoding="UTF-8"%>
<%@include file="common.jsp"%>
<%
  String bibcode = request.getParameter( "bibcode" );
  String text = request.getParameter( "text" );
  if (text != null && !text.trim().isEmpty())
    bibcode = null;
  int gramwidth = 2;
  try {
    gramwidth = Integer.parseInt( request.getParameter( "gramwidth" ) );
  } catch (Exception e) {
  }
  if (gramwidth < 2 || gramwidth > 5)
    gramwidth = 3;
  // default values
  boolean stoplist = true;
  boolean np = true;
  boolean locs = true;
  boolean lem = false;
  boolean sent = false;
  boolean reps = false;
  boolean bag = false;
  // 
  if (request.getParameter( "go" ) != null) {
    stoplist = bool( pageContext, "stoplist" );
    np = bool( pageContext, "np" );
    locs = bool( pageContext, "locs" );
    lem = bool( pageContext, "lem" );
    sent = bool( pageContext, "sent" );
    reps = bool( pageContext, "reps" );
    bag = bool( pageContext, "bag" );
  }
%>
<!DOCTYPE html>
<html>
<head>
<title>Collocations</title>
<link rel="stylesheet" type="text/css" href="alix.css" />
</head>
<body>
  <%@include file="menu.jsp"%>
  <article id="article">
    <h1>
      <a href=".">Alix</a> : <a href="?">collocations</a> (locutions et
      cooccurrences fréquentes)
    </h1>
    <form
      onsubmit="if (!this.text.value) return true; this.method = 'post'; this.action='?'; "
      method="get" action="">
      <select name="bibcode"
        onchange="this.form.text.value = ''; this.method = 'GET';  this.form.submit()">
        <%
          seltext( pageContext, bibcode );
        %>
      </select> <label> <select name="gramwidth"
        onchange="this.form.submit()">
          <%
            int[] values = { 2, 3, 4, 5 };
                        int lim = values.length;
                        String selected = "";
                        boolean seldone = false;
                        for (int i = 0; i < lim; i++) {
                          if (!seldone && values[i] == gramwidth) {
                            selected = " selected=\"selected\"";
                            seldone = true;
                          }
                          out.println( "<option" + selected + " value=\"" + values[i] + "\">" + values[i] + "</option>" );
                          selected = "";
                        }
                        String checked = " checked=\"checked\"";
          %>
      </select> mots
      </label> <br /> <label> <input name="stoplist" type="checkbox"
        value="1" <%if (stoplist)
        out.print( checked );%> /> mots vides
      </label> <label> <input name="np" type="checkbox"
        <%if (np)
        out.print( checked );%> /> noms propres
      </label> <label> <input name="lem" type="checkbox"
        <%if (lem)
        out.print( checked );%> /> lemmes
      </label> <label> <input name="locs" type="checkbox"
        <%if (locs)
        out.print( checked );%> /> locutions
      </label> <label> <input name="sent" type="checkbox"
        <%if (sent)
        out.print( checked );%> /> couper aux phrases
      </label> <label> <input name="reps" type="checkbox"
        <%if (reps)
        out.print( checked );%> /> répétitions
      </label> <label> <input name="bag" type="checkbox"
        <%if (bag)
        out.print( checked );%> /> sac de mots
      </label> <input type="hidden" name="go" value="go" />
      <button type="submit">Envoyer</button>
      <br />
      <textarea name="text" style="width: 100%; height: 10em;" cols=""
        rows="">
        <%
          if (text != null)
                    out.print( text );
        %>
      </textarea>
    </form>
    <%
      if (bibcode != null)
        text = text( pageContext, bibcode );
      if (text != null && !text.isEmpty()) {
        long time = System.nanoTime();

        IntBuffer key = new IntBuffer( gramwidth, bag ); // collocation key (series or bag)
        IntRoller gram = new IntRoller( 0, gramwidth - 1 ); // collocation wheel
        IntRoller wordmarks = new IntRoller( 0, gramwidth - 1 ); // positions of words recorded in the collocation key

        DicFreq words = new DicFreq();
        DicPhrase phrases = new DicPhrase();

        final int NAME = words.add( "NOM" );
        final int NUM = words.add( "NUM" );
        int senselevel = -1;
        if (stoplist) {
          BufferedReader buf = new BufferedReader(
              new InputStreamReader( Lexik.class.getResourceAsStream( "dic/stop.csv" ), StandardCharsets.UTF_8 ) );
          String l;
          // define a "sense level" in the dictionary, by inserting a stoplist at first
          while ((l = buf.readLine()) != null) {
            int code = words.add( l.trim() );
            if (code > senselevel)
              senselevel = code;
          }
          buf.close();
          // add some more words to the stoplits
          for (String w : new String[] { "chère", "dire", "dis", "dit", "jeune", "jeunes", "yeux" }) {
            int code = words.add( w );
            if (code > senselevel)
              senselevel = code;
          }
        }

        // out.print("<p>Initialisation : "+((System.nanoTime() - time) / 1000000) + " ms. ");
        time = System.nanoTime();

        IntRoller wordflow = new IntRoller( -15, 0 );
        int code;
        int exit = 1000;
        StringBuffer label = new StringBuffer();
        Occ occ = new Occ(); // pointer on current occurrence in the tokenizer flow
        Tokenizer toks = new Tokenizer( text );
        int occs = 0;
        while (true) {
          if (locs) {
            occ = toks.word();
            if (occ == null)
              break;
          }
          else {
            if (!toks.token( occ ))
              break;
          }
          // clear after sentences ?
          if (sent && occ.tag().equals( Tag.PUNsent )) {
            wordflow.clear();
            gram.clear();
            wordmarks.clear();
            continue;
          }

          if (occ.tag().isPun())
            continue; // do not record punctuation
          occs++; // do not count punctuation

          if (occ.tag().isNum())
            code = NUM; // simplify numbers
          else if (np && occ.tag().isName())
            code = NAME; // simplify names
          else if (!lem)
            code = words.add( occ.orth() ); // no lem
          else if (occ.tag().isVerb() || occ.tag().isAdj() || occ.tag().isSub())
            code = words.add( occ.lem() );
          else
            code = words.add( occ.orth() );
          // clear to avoid repetitions ?
          // « Voulez vous sortir, grand pied de grue, grand pied de grue, grand pied de grue »
          if (reps && code == wordflow.first()) {
            wordflow.clear();
            gram.clear();
            wordmarks.clear();
            continue;
          }

          wordflow.push( code ); // add this token to the word flow
          wordmarks.dec(); // decrement positions of the recorded plain words
          if (wordflow.get( 0 ) <= senselevel)
            continue; // do not record empty words
          wordmarks.push( 0 ); // record a new position of full word
          gram.push( wordflow.get( 0 ) ); // store a signficant word as a collocation key
          if (gram.get( 0 ) == 0)
            continue; // the collocation key is not complete

          key.set( gram ); // transfer the collocation wheel to a phrase key
          int count = phrases.inc( key );
          // new value, add a label to the collocation
          if (count == 1) {
            label.setLength( 0 );
            for (int i = wordmarks.get( 0 ); i <= 0; i++) {
              String w = words.label( wordflow.get( i ) );
              label.append( w ); 
              if (i == 0)
                ; // do not append space to end
              else if (label.length() > 1 && label.charAt( label.length() - 1 ) == '\'')
                ; // do not append space after apos
              else
                label.append( ' ' );
            }
            // System.out.println( label );
            phrases.label( key, label.toString() );
          }
          // if ( --exit < 0 ) System.exit( 1 );
        }

        out.print( "<p>" + ppmdf.format( occs ) + " occurrences, " + ppmdf.format( phrases.occs() ) + " collocations, "
            + ppmdf.format( phrases.size() ) + " différentes, en " + ((System.nanoTime() - time) / 1000000)
            + " ms.</p>\n" );
        phrases.html( out, 200, words );
      }
    %>
  </article>
</body>
</html>
