Pod::Spec.new do |s|
  s.name     = 'ISO8601DateFormatter'
  s.version  = '0.7'
  s.license  = 'BSD'
  s.summary  = 'A Cocoa NSFormatter subclass to convert dates to and from ISO-8601-formatted strings. Supports calendar, week, and ordinal formats.'
  s.homepage = 'https://bitbucket.org/boredzo/iso-8601-parser-unparser/'
  s.author   = 'Peter Hosey'
  s.source   = { :git => 'https://github.com/deltatre-spa/iso-8601-date-formatter.git', :tag => s.version.to_s }

  s.source_files = 'ISO8601DateFormatter.{h,m}'
end