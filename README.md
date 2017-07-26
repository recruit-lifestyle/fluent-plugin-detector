# Fluent::Plugin::Detector


## Installation

```
$ gem build fluent-plugin-detector.gemspec
$ td-agent-gem install fluent-plugin-detector.gem
```
Please use your preferable gem, like fluent-gem.

## Requirements

- fluentd 0.12.0+

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

## Contributions

Bug reports and pull requests are welcome on GitHub

## Credits

fluentd-plugin-detector is owned and maintained by [RECRUIT LIFESTYLE CO., LTD](https://www.recruit-lifestyle.co.jp/).


## License

```
Copyright (c) 2017 RECRUIT LIFESTYLE CO., LTD.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
