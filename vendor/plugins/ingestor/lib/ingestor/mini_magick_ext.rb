require 'mini_magick'
require 'ingestor/constants'
require 'set'

module Ingestor
  module MiniMagickExt
    module Image

      def self.included(klass)
        klass.class_eval{ include MiniMagick unless defined? Magick }
      end

      module Ext

        def self.included(base)
          base.extend ClassMethods
          base.class_eval do
            class << self
              alias_method_chain :open, :original_filepath
            end
          end
        end

        module ClassMethods

          def open_with_original_filepath(path)
            mini_magick_obj = open_without_original_filepath(path)
            mini_magick_obj.original_filepath = path
            mini_magick_obj
          end

        end

        include Ingestor::Constants

        attr_accessor :original_filepath

        def copy
          @copy ||= MiniMagick::Image.open(original_filepath)
        end

        def width
          self[:width]
        end

        def height
          self[:height]
        end

        def max_side
          [width, height].max
        end

        def portrait?
          height > width
        end

        def landscape?
          height < width
        end

        def square?
          height == width
        end

        def get_colorspace
          self["%[colorspace]"]
        end

        def gray?
          get_colorspace == 'Gray'
        end
        alias :grey? :gray?

        def factor_to_fit(square)
          square.to_f / max_side.to_f
        end

        # side is 'x' or 'y'
        # for example "135 PixelsPerInch" or "53.15 PixelsPerCentimeter"
        def full_resolution_info(side)
          self["%#{side}"]
        end

        # returns 'cm' or 'inch'
        def resolution_unit(side)
          case full_resolution_info(side).match(/\s(.+)/)[1]
          when 'PixelsPerCentimeter'  then 'cm'
          when 'PixelsPerInch'        then 'inch'
          end
        end

        def resolution_value(side)
          full_resolution_info(side).to_i
        end

        def resolution_ppi(side)
          case resolution_unit(side)
          when 'inch' then resolution_value(side)
          when 'cm'   then resolution_value(side)*2.54
          end
        end

        def x_ppi
          resolution_ppi('x')
        end
        alias :x_resolution :x_ppi

        def y_ppi
          resolution_ppi('y')
        end
        alias :y_resolution :y_ppi

        # Image file format
        # For more on the format command see http://www.imagemagick.org/script/command-line-options.php#format
        def magick_format
          self[:format]
        end

        def support_resolution?
          ['TIFF', 'JPEG', 'PNG'].include?(magick_format)
        end

        def resample_to_fit(square)
          unless support_resolution?
            raise MiniMagick::Invalid, "format of #{self.filename} does not support embedded resolution"
          end
          factor = factor_to_fit(square)
          resample("#{x_ppi*factor}x#{y_ppi*factor}")
          self
        end

        def max_side_resampled_at(target_resolution)
          max_side * target_resolution / (portrait? ? y_ppi : x_ppi)
        end

        def safe_resample(opts={})
          unless opts.keys.include?(:min_square) && opts.keys.to_set.subset?([:min_resolution, :min_square].to_set)
            raise ArgumentError, "options :min_square required, :min_resolution allowed"
          end

          if opts[:min_resolution] && max_side_resampled_at(opts[:min_resolution]) >= opts[:min_square]
            resample("#{opts[:min_resolution]}x#{opts[:min_resolution]}")
          else
            resample_to_fit(opts[:min_square])
          end
          self
        end

      end # module Ext

      MiniMagick::Image.class_eval{ include Ext }

      module Templates
        include Ingestor::Constants

        # available templates:
        #   :broadsheet_color
        #   :broadsheet_grayscale
        #   :smallbook_color
        #   :smallbook_grayscale
        def write_using_template(template, fullpath)
          send("write_#{template}", fullpath)
        end

        def format_from_path(path)
          File.extname(path).gsub(/^\./,'').upcase
        end

        # min dpi => 120, min square => 1280, colorspace => unchanged, jpg quality => 15
        def write_broadsheet_color(fullpath, format=format_from_path(fullpath))
          safe_resample(:min_resolution => MIN_DPI_LARGE, :min_square => MIN_SQUARE_LARGE)
          self.format(format)
          self.quality('15')
          write(fullpath)
        end

        # min dpi => 120, min square => 1280, colorspace => gray, jpg quality => 15
        def write_broadsheet_grayscale(fullpath, format=format_from_path(fullpath))
          safe_resample(:min_resolution => MIN_DPI_LARGE, :min_square => MIN_SQUARE_LARGE)
          self.colorspace('Gray')
          self.format(format)
          self.quality('15')
          write(fullpath)
        end

        # min dpi => 120, min square => 1280, colorspace => unchanged, jpg quality => 60
        # default template
        def write_smallbook_color(fullpath, format=format_from_path(fullpath))
          safe_resample(:min_resolution => MIN_DPI_LARGE, :min_square => MIN_SQUARE_LARGE)
          self.format(format)
          self.quality('60')
          write(fullpath)
        end

        # min dpi => 120, min square => 1280, colorspace => gray, jpg quality => 60
        # default template
        def write_smallbook_grayscale(fullpath, format=format_from_path(fullpath))
          safe_resample(:min_resolution => MIN_DPI_LARGE, :min_square => MIN_SQUARE_LARGE)
          self.colorspace('Gray')
          self.format(format)
          self.quality('60')
          write(fullpath)
        end
      end # module Templates

      MiniMagick::Image.class_eval{ include Templates }

    end # module Image
  end  # module Magick
end # module Ingestor

