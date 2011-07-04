require 'zlib'

module GradientPng

  def self.vertical_gradient(filename, start_color, stop_color, height)
    colors = gradient(start_color, stop_color, height)
    image_data = interpolate(0, [height - 1, 255].min, height).map { |b| [0, b] } # filter 0 for each scanline
    png_bytes = signature + header(1, height) + pallete(colors) + data(image_data) + last
    write_bytes_to_file(filename, png_bytes)
  end

  def self.horizontal_gradient(filename, start_color, stop_color, width)
    colors = gradient(start_color, stop_color, width)
    image_data = [0] + interpolate(0, [width - 1, 255].min, width) # filter 0 for the one scanline
    png_bytes = signature + header(width, 1) + pallete(colors) + data(image_data) + last
    write_bytes_to_file(filename, png_bytes)
  end

  private

  def self.signature
    [137, 80, 78, 71, 13, 10, 26, 10]
  end

  def self.byte_array_from_number(num, bytes)
    (bytes - 1).downto(0).collect { |byte| 
      ((num >> (byte * 8)) & 0xFF) 
    } 
  end 

  def self.header(width, height)
    bytes = [

      # width, 4 bytes
      byte_array_from_number(width, 4),

      # height, 4 bytes
      byte_array_from_number(height, 4),

      # bit depth = 8, 1 byte
      8,

      # color type = 3 (pallete used, color used), 1 byte
      3,  

      # compression mode = 0 (deflate/inflate), 1 byte
      0,

      # filter mode = 0, 1 byte
      0,

      # interlace mode = 0, 1 byte
      0
    ]
    chunk('IHDR', bytes.flatten)
  end

  def self.pallete(colors)
    chunk('PLTE', colors.flatten)
  end

  def self.data(bytes)
    chunk('IDAT', Zlib::Deflate.deflate(bytes.flatten.pack('C*')).unpack('C*'))
  end

  def self.last
    chunk('IEND', [])
  end

  def self.chunk(type, bytes)
    [
      # length, 4 bytes
      byte_array_from_number(bytes.length, 4),

      # chunk type, 4 bytes
      byte_array_from_number(type.unpack('N*')[0], 4),

      # chunk contents
      bytes,
      
      # crc check of type and contents
      byte_array_from_number(bytes.any? ? Zlib.crc32(type + bytes.pack('C*')) : Zlib.crc32(type), 4)

    ].flatten
  end

  def self.interpolate(start, stop, count)
    (0..count).to_a.map do |i|
      (start + (i/count.to_f * (stop - start))).round
    end
  end

  def self.write_bytes_to_file(filename, bytes)
    File.open(filename, 'wb') do |file|
      bytes.each do |byte|
        file.print byte.chr
      end 
    end
  end

  def self.gradient(start_color, stop_color, count)
    count = [count, 255].min
    r = interpolate(start_color[0], stop_color[0], count)
    g = interpolate(start_color[1], stop_color[1], count)
    b = interpolate(start_color[2], stop_color[2], count)
    (0..count).to_a.map do |i|
      [r[i], g[i], b[i]]
    end
  end

end

GradientPng.vertical_gradient('vgradient.png', [230, 230, 230], [180, 180, 180], 150)
GradientPng.horizontal_gradient('hgradient.png', [230, 230, 230], [180, 180, 180], 600)
