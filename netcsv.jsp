<%@ page language="java" contentType="text/plain; charset=UTF-8" pageEncoding="UTF-8"%><%@ page import="
java.util.LinkedList,
site.oeuvres.util.Char,
site.oeuvres.fr.Lexik,
site.oeuvres.fr.Tokenizer
" %><%!
public class Couple {
  int pos;
  String name;
  public Couple( int pos, String form ) {
    this.pos = pos;
    this.name = form;
  }
  public String append(String form) {
    this.name += form;
    return this.name;
  }
  public String toString() {
    return ""+pos+":"+name;
  }
}
%><%
request.setCharacterEncoding("UTF-8");
response.setHeader( "Content-Disposition", "attachment; filename=\"edges.csv\"" );
out.print("Source,Target\n");
String text = request.getParameter( "text" );
if ( text == null) text = "";
int width = 10;
String swidth = request.getParameter( "width" );
if ( swidth != null) width = Integer.parseInt( swidth );
if ( width < 0 ) width = 10;
Tokenizer toks = new Tokenizer(text);
int pos = 0;
String form;
String name;
String last = null;
String pre = " ";
LinkedList<Couple> queue = new LinkedList<Couple>();
Couple couple;
/*
M. l'évêque de Digne
M. le curé
La Haye
*/
while ( toks.read() ) {
  pos++;
  form = toks.getString();
  if ( last == null);
  else if ("de".equals(form)) {
    pre = " de ";
    continue;
  }
  else if ("d'".equals(form)) {
    pre = " d'";
    continue;
  }
  if ( !Char.isUpperCase( form.charAt( 0 ) )) {
    // fin de nom on traite la pile
    if ( last != null) {
      pre = " ";
      couple = queue.peekLast();
      int from = couple.pos;
      name = couple.name;
      while ( true ) {
        couple = queue.peekFirst();
        if ( from - couple.pos <= width ) break;
        queue.removeFirst();
      }
      for (Couple dest: queue) {
        if ( dest.name.equals( name )) continue;
        out.print( name );
        out.print( "," );
        out.print( dest.name );
        out.print( "\n" );
      }
      last = null;
    }
    
    continue;
  }
  if (last != null) {
    couple = queue.pollLast();
    couple.append( pre +form );
    pre = " ";
    queue.add( couple );
    last = form;
    continue;
  }
  queue.add( new Couple(pos, form) );
  last = form;
}
       
%>