require 'zlib'

module GradientPng

  def self.vertical_gradient(filename, start_color, stop_color, height)
    colors = gradient(start_color, stop_color, height)
    image_data = interpolate(0, [height - 1, 255].min, height).map{|b| [0, b]}.flatten.pack('C*') # filter 0 for each scanline
    png_str = signature << header(1, height) << pallete(colors) << data(image_data) << last
    write_bytes_to_file(filename, png_str)
  end

  def self.horizontal_gradient(filename, start_color, stop_color, width)
    colors = gradient(start_color, stop_color, width)
    image_data = "\x00" << interpolate(0, [width - 1, 255].min, width).pack('C*') # filter 0 for the one scanline
    png_str = signature + header(width, 1) + pallete(colors) + data(image_data) + last
    write_bytes_to_file(filename, png_str)
  end

  def self.signature
    "\211PNG\r\n\032\n"
  end

  def self.header(width, height)
    # A-E are one byte each
    # A: bit depth
    # B: color type (3 = pallete used and color used)
    # C: compression mode (0 = deflate/inflate)
    # D: filter mode
    # E: interlace mode (0 = not interlaced)
    # four bytes for width and height                  [A, B, C, D, E]
    bytes = [width].pack('N') << [height].pack('N') << [8, 3, 0, 0, 0].pack('C*')
    chunk('IHDR', bytes)
  end

  def self.pallete(colors)
    chunk('PLTE', colors)
  end

  def self.data(content)
    chunk('IDAT', Zlib::Deflate.deflate(content))
  end

  def self.last
    chunk('IEND', '')
  end

  def self.chunk(type, content)
    # 4 byte length, 4 byte chunk type, X bytes chunk content, 4 byte CRC of type and content
    [content.length].pack('N') << type << content << [Zlib.crc32(type << content)].pack('N')
  end

  def self.interpolate(start, stop, count)
    (0..count).to_a.map do |i|
      (start + (i/count.to_f * (stop - start))).round
    end
  end

  def self.write_bytes_to_file(filename, string)
    File.open(filename, 'wb') do |file|
      file << string
    end
    filename
  end

  def self.gradient(start_color, stop_color, count)
    count = [count, 255].min
    r = interpolate(start_color[0], stop_color[0], count)
    g = interpolate(start_color[1], stop_color[1], count)
    b = interpolate(start_color[2], stop_color[2], count)
    colors = (0..count).to_a.map do |i|
      [r[i], g[i], b[i]]
    end
    colors.flatten.pack('C*')
  end

end
