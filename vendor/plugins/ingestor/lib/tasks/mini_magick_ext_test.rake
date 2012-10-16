namespace :mini_magick_ext do
  desc "Custom task to test the MiniMagick extensions"
  task :test => :environment do
    require 'pry'
    require 'minitest/autorun'
    require 'fileutils'

    include Ingestor::MiniMagickExt::Image

    describe Ingestor::MiniMagickExt::Image do

      it 'must have a open_with_original_filepath method chain' do
        MiniMagick::Image.must_respond_to :open_without_original_filepath
        MiniMagick::Image.must_respond_to :open_with_original_filepath
      end

      before do
        @img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_gray.tif")
      end

      describe 'when initialized' do

        it 'must retain the original_filepath if the overwritten open does work' do
          @img.original_filepath.must_equal "#{File.dirname(__FILE__)}/mini_magick_ext_test_gray.tif"
        end

        it 'must have a width' do
          @img.width.must_equal 1534
        end

        it 'must have a height' do
          @img.height.must_equal 2038
        end

        it 'must have a max_side' do
          @img.max_side.must_equal 2038
        end

        it 'must be able to tell if it is portrait' do
          @img.portrait?.must_equal true
        end

        it 'must be able to tell if it is landscape' do
          @img.landscape?.must_equal false
        end

        it 'must be able to tell if it is square' do
          @img.square?.must_equal false
        end

        it 'must have a x resolution in pixels per inch' do
          @img.x_ppi.must_equal 400
        end

        it 'must have a y resolution in pixels per inch' do
          @img.y_ppi.must_equal 400
        end

        it 'must have a magick_format' do
          @img.magick_format.must_equal 'TIFF'
        end

        it 'must be able to tell if it supports resolution' do
          @img.support_resolution?.must_equal true
        end

        it 'must be able to tell its colorspace' do
          gray_img  = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_gray.tif")
          color_img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_color.tif")

          gray_img.get_colorspace.must_equal 'Gray'
          color_img.get_colorspace.must_equal 'RGB'
        end

        it 'must be able to tell if it is gray' do
          gray_img  = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_gray.tif")
          color_img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_color.tif")

          gray_img.gray?.must_equal true
          color_img.gray?.must_equal false
          gray_img.grey?.must_equal true
          color_img.grey?.must_equal false
        end
      end

      describe 'processing abilities' do
        it 'must be able to create a copy of itself, starting from the original file' do
          copy = @img.copy

          copy.path.wont_equal @img.path
          copy.original_filepath.must_equal @img.original_filepath

          original_width = @img.width
          original_height = @img.height
          @img.resize("10x10")
          @img.height.must_equal 10
          copy.width.must_equal original_width
          copy.height.must_equal original_height
        end

        it 'must be able to compute a factor to fit a given circumscribing square of x pixels' do
          @img.factor_to_fit(300).must_be_close_to 0.14720314033366
          @img.factor_to_fit(250).must_be_close_to 0.122669283611384
          @img.factor_to_fit(100).must_be_close_to 0.0490677134445535
        end

        it 'must be able to compute the size of its max side if resampled at a given resolution' do
          @img.max_side_resampled_at(120).must_equal 611
          @img.max_side_resampled_at(72).must_equal 366
          @img.max_side_resampled_at(200).must_equal 1019
        end

        it 'must be able to resample given not the resolution but the final max side' do
          img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_gray.tif")

          out_path = "#{File.dirname(__FILE__)}/mini_magick_ext_test_resampled_to_fit_450.jpeg"
          img.resample_to_fit(450).write(out_path)

          out_img = MiniMagick::Image.open(out_path)
          out_img.max_side.must_equal 450
          out_img.width.must_equal 339
          out_img.height.must_equal 450

          require 'fileutils'
          FileUtils.rm(out_path)
        end

        it 'must be able to safely resample preserving a min size' do
          img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_gray.tif")

          out_path = "#{File.dirname(__FILE__)}/mini_magick_ext_test_safe_resampled_min_res_120_min_size_800.jpeg"
          img.safe_resample(:min_resolution => 120, :min_square => 800).write(out_path)

          out_img = MiniMagick::Image.open(out_path)
          out_img.max_side.must_equal 800
          out_img.width.must_equal 602
          out_img.height.must_equal 800
          out_img.x_ppi.must_equal 157
          out_img.y_ppi.must_equal 157

          FileUtils.rm(out_path)
        end

        it 'must be able to safely resample preserving a min resolution' do
          img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_gray.tif")

          out_path = "#{File.dirname(__FILE__)}/mini_magick_ext_test_safe_resampled_min_res_120_min_size_250.jpeg"
          img.safe_resample(:min_resolution => 120, :min_square => 250).write(out_path)

          out_img = MiniMagick::Image.open(out_path)
          out_img.max_side.must_equal 611
          out_img.width.must_equal 460
          out_img.height.must_equal 611
          out_img.x_ppi.must_equal 120
          out_img.y_ppi.must_equal 120

          FileUtils.rm(out_path)
        end

        it 'must be able to extract the format from the destination path' do
          img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_gray.tif")

          out_path = "#{File.dirname(__FILE__)}/mini_magick_ext_test_write_broadsheet_color.jpeg"

          img.format_from_path(out_path).must_equal 'JPEG'
        end

        it 'must process with write_broadsheet_color template' do
          img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_color.tif")

          out_path = "#{File.dirname(__FILE__)}/mini_magick_ext_test_write_broadsheet_color.jpeg"
          img["%[colorspace]"].must_equal 'RGB'
          img.write_broadsheet_color(out_path)

          out_img = MiniMagick::Image.open(out_path)
          out_img.width.must_equal 985
          out_img.height.must_equal 1280
          out_img.x_ppi.must_equal 134
          out_img.y_ppi.must_equal 134
          out_img.x_ppi.must_be :'>=', Ingestor::MIN_DPI_LARGE
          out_img.y_ppi.must_be :'>=', Ingestor::MIN_DPI_LARGE
          out_img.max_side.must_be :'>=', Ingestor::MIN_SQUARE_LARGE
          out_img["%C"].must_equal 'JPEG'
          out_img["%Q"].to_i.must_equal 15
          out_img["%[colorspace]"].must_equal 'RGB'

          FileUtils.rm(out_path)
        end

        it 'must process with write_broadsheet_grayscale template' do
          img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_color.tif")

          out_path = "#{File.dirname(__FILE__)}/mini_magick_ext_test_write_broadsheet_grayscale.jpeg"
          img["%[colorspace]"].must_equal 'RGB'
          img.write_broadsheet_grayscale(out_path)

          out_img = MiniMagick::Image.open(out_path)
          out_img.width.must_equal 985
          out_img.height.must_equal 1280
          out_img.x_ppi.must_equal 134
          out_img.y_ppi.must_equal 134
          out_img.x_ppi.must_be :'>=', Ingestor::MIN_DPI_LARGE
          out_img.y_ppi.must_be :'>=', Ingestor::MIN_DPI_LARGE
          out_img.max_side.must_be :'>=', Ingestor::MIN_SQUARE_LARGE
          out_img["%C"].must_equal 'JPEG'
          out_img["%Q"].to_i.must_equal 15
          out_img["%[colorspace]"].must_equal 'Gray'

          FileUtils.rm(out_path)
        end

        it 'must process with write_smallbook_color template' do
          img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_color.tif")

          out_path = "#{File.dirname(__FILE__)}/mini_magick_ext_test_write_smallbook_color.jpeg"
          img["%[colorspace]"].must_equal 'RGB'
          img.write_smallbook_color(out_path)

          out_img = MiniMagick::Image.open(out_path)
          out_img.width.must_equal 985
          out_img.height.must_equal 1280
          out_img.x_ppi.must_equal 134
          out_img.y_ppi.must_equal 134
          out_img.x_ppi.must_be :'>=', Ingestor::MIN_DPI_LARGE
          out_img.y_ppi.must_be :'>=', Ingestor::MIN_DPI_LARGE
          out_img.max_side.must_be :'>=', Ingestor::MIN_SQUARE_LARGE
          out_img["%C"].must_equal 'JPEG'
          out_img["%Q"].to_i.must_equal 60
          out_img["%[colorspace]"].must_equal 'RGB'

          FileUtils.rm(out_path)
        end

        it 'must process with write_smallbook_grayscale template' do
          img = MiniMagick::Image.open("#{File.dirname(__FILE__)}/mini_magick_ext_test_color.tif")

          out_path = "#{File.dirname(__FILE__)}/mini_magick_ext_test_write_smallbook_grayscale.jpeg"
          img["%[colorspace]"].must_equal 'RGB'
          img.write_smallbook_grayscale(out_path)

          out_img = MiniMagick::Image.open(out_path)
          out_img.width.must_equal 985
          out_img.height.must_equal 1280
          out_img.x_ppi.must_equal 134
          out_img.y_ppi.must_equal 134
          out_img.x_ppi.must_be :'>=', Ingestor::MIN_DPI_LARGE
          out_img.y_ppi.must_be :'>=', Ingestor::MIN_DPI_LARGE
          out_img.max_side.must_be :'>=', Ingestor::MIN_SQUARE_LARGE
          out_img["%C"].must_equal 'JPEG'
          out_img["%Q"].to_i.must_equal 60
          out_img["%[colorspace]"].must_equal 'Gray'

          FileUtils.rm(out_path)
        end

      end

    end

  end
end

