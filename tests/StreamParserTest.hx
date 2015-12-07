package;

import haxe.Timer;
import haxe.unit.TestCase;
import tink.io.Source;
import tink.io.StreamParser;

using tink.CoreApi;

class StreamParserTest extends TestCase {
  function testSingleSteps() {
    var source:Source = 'hello  world\t \r!!!';
    source.parse(new UntilSpace()).handle(function (x) {
      var x = x.sure();
      assertEquals('hello', x.data);
      //trace(x.rest);
      x.rest.parse(new UntilSpace()).handle(function (y) x = y.sure());
      assertEquals('world', x.data);
      x.rest.parse(new UntilSpace()).handle(function (y) x = y.sure());
      assertEquals('!!!', x.data);
    });
  }
  
  function testSplit() {
    var str = 'hello !!! world !!!!! !!! !!';
    var source:Source = str,
        a = [];
    source.parseWhile(new Splitter('!!!'), function (x) return Future.sync(a.push(x.toString()) > 0)).handle(function (x) {
      assertTrue(x.isSuccess());
      assertEquals('hello , world ,!! , !!', a.join(','));
    });
  }
  
  function testSplitSpeed() {
    var str = 'werlfkmwerf';
    
    for (i in 0...15)
      str += str;
      
    var chunk = str,
        delim = '---';
    
    str += delim;
    
    for (i in 0...3)
      str += str;
      
    trace(str.length);    
    var start = Timer.stamp();
    (str : Source).parseWhile(new Splitter(delim), function (x) return Future.sync(true)).handle(function (x) {
      trace(Timer.stamp() - start);
    });

  }
  
  function testParseWhile() {
    var str = 'hello world !!! how are you ??? ignore all this';
    
    var source:Source = str,
        a = [];
    source.parseWhile(new UntilSpace(), function (x) return Future.sync(a.push(x) < 7)).handle(function (x) {
      assertTrue(x.isSuccess());
      assertEquals('hello world !!! how are you ???', a.join(' '));
    });
    
  }
  
  function testStreaming() {
    var str = 'hello world !!! how are you ??? ignore all this';
    
    var source:Source = str;
    source.parseStream(new UntilSpace()).fold('', function (a, b) return '$b-$a').handle(function (x) {
      assertEquals(' $str'.split(' ').join('-'), x.sure());
    });
  }
}

private class UntilSpace extends ByteWiseParser<String> {
  
  var buf:StringBuf;
  
  public function new() {
    super();
    this.buf = new StringBuf();
  }
  
  override function read(c:Int):ParseStep<String> {
    return
      switch c {
        case white if (white <= ' '.code):
          var ret = buf.toString();
          if (ret == '')
            Progressed;
          else {
            buf = new StringBuf();
            Done(ret);
          }
        default:
          buf.addChar(c);
          Progressed;
      }
  }
}