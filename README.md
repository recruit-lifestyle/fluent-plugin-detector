# Fluent::Plugin::Detector


## Installation

```
$ td-agent-gem install fluent-plugin-detector
```
Please use your preferable gem, like fluent-gem.

## Configuration  

config #1:
```xml
<filter test.**>
  @type detector
  <allow>
    encoding UTF-8
  </allow>
</filter>
```
or config #2:
```xml
<filter test.**>
  @type detector
  <deny>
    encoding UTF-8
  </deny>
</filter>
```
You can identify multiple encodings using comma, like `encoding UTF-8,ASCII,EUC-JP`.
About the list of encoding, please visit the ruby-doc official page.
http://ruby-doc.org/core-2.3.0/Encoding.html

## Usage
#### Example Input
```
test.hoge {"test":"sentence", "sjis":"ごはん"}  
test.fuga {"test":"sentence", "utf8":"ごはん"}  
```
here, we assume that two ごはん are encoded in Shift_JIS and utf_8, respectively.  

#### Example Output  
In the case of config #1:
```
test.fuga {"test":"sentence", "utf8":"ごはん"}
```
In #2:
```
test.fuga {"test":"sentence", "sjis":"ごはん"}
```
#### Example Input 2
```
test.mega {"sjis":"ごはん", "utf8":"ごはん"}  
```
#### Example Output 2
In both cases, there will be no output.


### Details

```
<allow>
  quantifier all
  encoding UTF-8
</allow>
```
-> if all record value is encoded in UTF-8, the record passes.
```
<allow>
  quantifier any
  encoding UTF-8
</allow>
```
-> if at least one record value is encoded in UTF-8, the record passes.
```
<deny>
  quantifier all
  encoding UTF-8
</deny>
```
-> if all record value is encoded in UTF-8, the record does not pass.
```
<deny>
  quantifier any
  encoding UTF-8
</deny>
```
-> if at least one record value is encoded in UTF-8, the record does not pass.


## Practical Usage
To detect records encoded in neither UTF-8 nor ASCII,
```xml
<filter test.**>
  @type detector
  quantifier any
  <deny>
    encoding UTF-8, ASCII
  </deny>
</filter>
<match test.**>
  send records without UTF-8 and ASCII to...
</match>
```
To detect records including at least 1 value encoded in Shift-JIS, 
```xml
<filter test.**>
  @type detector
  quantifier any
  <allow>
    encoding Shift_JIS
  </allow>
</filter>
<match test.**>
  send records including at least 1 Shift-JIS value to...
</match>
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mihirat/fluent-plugin-detector.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

