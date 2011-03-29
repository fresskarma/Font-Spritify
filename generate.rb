#!/usr/bin/env ruby

# The "-debug annotate" method was added to IM v6.3.9-2 
# So this script works from there on

#convert -background transparent -fill white -font font.ttf -pointsize 72 label:"1" label.png

require 'pp'

fontsizes = [30, 37, 170]
#fontsizes = [30]

gridSize = nil # Use maximum glyph size if nil

glyphs = "1234567890.".split('')

def retrieveGlyphSizes(glyphs, fontsizes)
  glyphData = {}
  maxWidth = 0
  maxHeight = 0
  
  fontsizes.each do |fontsize|
    
    # Fetch glyph data
    cmd = "convert xc: -font font.ttf -debug annotate "
    glyphs.each do |glyph|
      cmd += "-pointsize #{fontsize} -annotate 0 '#{glyph}' "
    end
    cmd += "null: 2>&1 | grep Metrics:"
    resultData = (%x[#{cmd}]).split("\n")
    
    # Process glyph data
    glyphData[fontsize] = {}
    resultData.each do |row|
      row = row.sub("Metrics:", "").strip
      properties = row.split(';').map { |x| x.split(':').map { |y| y.strip } }
      properties = Hash[*properties.flatten()]
      
      properties["bounds"] = properties["bounds"].split(' ').map { |x| x.split(',') }.flatten
      properties["origin"] = properties["origin"].split(',')
      
      width = properties["width"].to_i
      if(properties["bounds"][2].to_i > width)
        width = properties["bounds"][2].to_i
        properties["width"] = properties["bounds"][2]
      end
      
      height = properties["height"].to_i
      
      maxWidth = width if width > maxWidth
      maxHeight = height if height > maxHeight
      
      glyphData[fontsize][properties["text"]] = properties
    end
  end

  [glyphData, maxWidth, maxHeight]
end

def cssSelectorCharacter(char)
  replace = {'.' => 'dot'}
  return replace[char] unless replace[char].nil?
  char
end

puts "Retrieving Glyph Data..."
glyphData, maxWidth, maxHeight = *retrieveGlyphSizes(glyphs, fontsizes);

gridSize = [maxWidth, maxHeight].max if gridSize.nil?


pp glyphData

#cmd = "convert -background transparent -fill white -font font.ttf -pointsize 72 "

imageHeight = fontsizes.length *  gridSize
imageWidth  = glyphs.length * gridSize

pp gridSize

puts "Rendering Sprite..."
cmd = "convert -size #{imageWidth}x#{imageHeight} xc:transparent -gravity NorthWest -font font.ttf -fill white "

y = 0
fontsizes.each do |fontsize|
  x = 0
  glyphs.each do |glyph|
    cmd +=  "-pointsize #{fontsize} -annotate +#{x*gridSize}+#{y*gridSize} '#{glyph}' "
    x += 1
  end
  y += 1
end

cmd += " outfoo.png"

%x[#{cmd}]


css = ""
html = ""
fontsizes.each do |fontsize|
  glyphs.each do |glyph|
    
    css += <<-EOF
.glyph_#{cssSelectorCharacter(glyph)}_size_#{fontsize} {
  background: url(outfoo.png);
  background-position: -#{glyphs.index(glyph)*gridSize}px -#{fontsizes.index(fontsize)*gridSize}px;
  width: #{glyphData[fontsize][glyph]["origin"][0]}px;
  height: #{glyphData[fontsize][glyph]["height"]}px;
  float: left;
  margin-right: 0px;
}
EOF
  
    html += <<-EOF
<div class="glyph_#{cssSelectorCharacter(glyph)}_size_#{fontsize}"></div>
EOF
  end
end

def writeString(string, fontsize)
  html = ''
  string.split('').each do |glyph|
    html += <<-EOF
<div class="glyph_#{glyph}_size_#{fontsize}"></div>
EOF
  end
  html + "<div class='clear: both;'></div>"
end

doc = <<-EOF

<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <title>Virtual Library</title>
    <style type="text/css">
#{css}
    </style>
  </head>
  <body>
    #{html}
  </body>
</html>
EOF

File.open("test.html", 'w') {|f| f.write(doc) }

#pp glyphs
#pp cmd