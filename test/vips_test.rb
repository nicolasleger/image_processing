require "test_helper"
require "image_processing/vips"
require "mini_magick"

describe ImageProcessing::Vips do
  include ImageProcessing::Vips

  def assert_similar(expected, actual)
    return if RUBY_ENGINE == "jruby"

    a = Phashion::Image.new(expected.path)
    b = Phashion::Image.new(actual.path)

    distance = a.distance_from(b).abs

    assert_operator distance, :<=, 4
  end

  def assert_dimensions(dimensions, file)
    assert_equal dimensions, Vips::Image.new_from_file(file.path).size
  end

  def assert_type(type, file)
    assert_equal type, MiniMagick::Image.new(file.path).type
  end

  before do
    @portrait  = copy_to_tempfile(fixture_path("portrait.jpg"))
    @landscape = copy_to_tempfile(fixture_path("landscape.jpg"))
  end

  describe "#convert" do
    it "changes the image format" do
      result = convert(@portrait, "png")
      assert_type "PNG", result
      assert_equal ".png", File.extname(result.path)
    end

    it "doesn't modify the input file" do
      convert(@portrait, "png")
      assert File.exist?(@portrait.path)
    end
  end

  describe "#auto_orient" do
    it "fixes the orientation of the image" do
      rotated = fixture_image("rotated.jpg")
      actual = auto_orient(rotated)
      expected = with_ruby_vips(rotated, &:rot90)
      assert_similar expected, actual
    end

    it "doesn't modify the input file" do
      auto_orient(@portrait)
      assert_equal fixture_image("portrait.jpg").read, @portrait.read
    end
  end

  describe "#resize_to_limit" do
    it "resizes the image up to a given limit" do
      result = resize_to_limit(@portrait, 400, 400)
      assert_dimensions [300, 400], result
    end

    it "does not resize the image if it is smaller than the limit" do
      result = resize_to_limit(@portrait, 1000, 1000)
      assert_dimensions [600, 800], result
    end

    it "auto rotates the image" do
      rotated = fixture_image("rotated.jpg")
      actual = resize_to_limit(rotated, 400, 400)
      expected = resize_to_limit(auto_orient(rotated), 400, 400)
      assert_similar expected, actual
    end

    it "produces correct image" do
      result = resize_to_limit(@portrait, 400, 400)
      assert_similar fixture_image("limit.jpg"), result
    end

    it "doesn't modify the input file" do
      resize_to_limit(@portrait, 400, 400)
      assert_equal fixture_image("portrait.jpg").read, @portrait.read
    end
  end

  describe "#resize_to_fit" do
    it "resizes the image to fit given dimensions" do
      result = resize_to_fit(@portrait, 400, 400)
      assert_dimensions [300, 400], result
    end

    it "enlarges image if it is smaller than given dimensions" do
      result = resize_to_fit(@portrait, 1000, 1000)
      assert_dimensions [750, 1000], result
    end

    it "auto rotates the image" do
      rotated = fixture_image("rotated.jpg")
      actual = resize_to_fit(rotated, 400, 400)
      expected = resize_to_fit(auto_orient(rotated), 400, 400)
      assert_similar expected, actual
    end

    it "produces correct image" do
      result = resize_to_fit(@portrait, 400, 400)
      assert_similar fixture_image("fit.jpg"), result
    end

    it "doesn't modify the input file" do
      resize_to_fit(@portrait, 400, 400)
      assert_equal fixture_image("portrait.jpg").read, @portrait.read
    end
  end

  describe "#resize_to_fill" do
    it "resizes and crops the image to fill out the given dimensions" do
      result = resize_to_fill(@portrait, 400, 400)
      assert_dimensions [400, 400], result
    end

    it "enlarges image and crops it if it is smaller than given dimensions" do
      result = resize_to_fill(@portrait, 1000, 1000)
      assert_dimensions [1000, 1000], result
    end

    it "auto rotates the image" do
      rotated = fixture_image("rotated.jpg")
      actual = resize_to_fill(rotated, 400, 400)
      expected = resize_to_fill(auto_orient(rotated), 400, 400)
      assert_similar expected, actual
    end

    it "produces correct image" do
      result = resize_to_fill(@portrait, 400, 400)
      assert_similar fixture_image("fill.jpg"), result
    end

    it "doesn't modify the input file" do
      resize_to_fill(@portrait, 400, 400)
      assert_equal fixture_image("portrait.jpg").read, @portrait.read
    end
  end

  describe "#resize_and_pad" do
    it "resizes and fills out the remaining space to fill out the given dimensions" do
      result = resize_and_pad(@portrait, 400, 400)
      assert_dimensions [400, 400], result
    end

    it "enlarges image and fills out the remaining space to fill out the given dimensions" do
      result = resize_and_pad(@portrait, 1000, 1000, background: "red")
      assert_dimensions [1000, 1000], result
    end

    it "auto rotates the image" do
      rotated = fixture_image("rotated.jpg")
      actual = resize_and_pad(rotated, 400, 400)
      expected = resize_and_pad(auto_orient(rotated), 400, 400)
      assert_similar expected, actual
    end

    it "produces correct image" do
      @portrait = convert(@portrait, "png")
      result = resize_and_pad(@portrait, 400, 400, background: "red")
      assert_similar fixture_image("pad.jpg"), result
    end

    it "produces correct image when enlarging" do
      result = resize_and_pad(@landscape, 1000, 1000, background: "green")
      assert_similar fixture_image("pad-large.jpg"), result
    end

    it "doesn't modify the input file" do
      resize_and_pad(@portrait, 400, 400)
      assert_equal fixture_image("portrait.jpg").read, @portrait.read
    end
  end

  describe "#crop" do
    it "resizes the image to the given dimensions" do
      result = crop(@portrait, 50, 50)
      assert_dimensions [50, 50], result
    end

    it "crops the right area of the images from the center" do
      result = crop(@portrait, 50, 50, gravity: 'Center')
      assert_similar fixture_image("crop-center-vips.jpg"), result
    end

    it "doesn't modify the input file" do
      crop(@portrait, 50, 50)
      assert_equal fixture_image("portrait.jpg").read, @portrait.read
    end
  end
end
