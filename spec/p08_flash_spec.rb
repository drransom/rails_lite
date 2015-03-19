require 'webrick'
require 'phase8/controller_base'
require 'phase8/flash'
require 'pry-byebug'

describe Phase8::Flash do
  let(:req) { WEBrick::HTTPRequest.new(Logger: nil) }
  let(:res) { WEBrick::HTTPResponse.new(HTTPVersion: '1.0') }
  let(:cook) { WEBrick::Cookie.new('_rails_lite_flash', { xyz: 'abc' }.to_json) }


  it "deserializes json cookie if one exists" do
    req.cookies << cook
    flash = Phase8::Flash.new(req)
    expect(flash[:xyz]).to eq 'abc'
    expect(flash.now[:xyz]).to eq 'abc'
  end

  describe '#store_flash' do
    context "without cookies in request" do
      before(:each) do
        flash = Phase8::Flash.new(req)
        flash[:first_key] = 'first_val'
        flash.store_flash(res)
      end

      it "adds new cookie with '_rails_lite_flash' name to response" do
        cookie = res.cookies.find { |c| c.name == '_rails_lite_flash' }
        expect(cookie).to_not be nil
      end

      it "stores the cookie in json format" do
        cookie = res.cookies.find { |c| c.name == '_rails_lite_flash' }
        JSON.parse(cookie.value).should be_a(Hash)
      end
    end

    context 'with cookies in request' do
      before(:each) do
        cook = WEBrick::Cookie.new('_rails_lite_flash',
          { pho: "soup" }.to_json)
        req.cookies << cook
      end

      it 'reads the flash data into the flash' do
        flash = Phase8::Flash.new(req)
        expect(flash[:pho]).to eq 'soup'
      end

      it 'reads the flash data into flash.now' do
        flash = Phase8::Flash.new(req)
        expect(flash.now[:pho]).to eq 'soup'
      end
    end

    context 'retreiving/saving flash data' do

      it 'finds data that was entered into flash.now' do
        flash = Phase8::Flash.new(req)
        flash.now[:errors] = 'This is a redirect error'
        expect(flash[:errors]). to eq 'This is a redirect error'
      end

      it 'saves flash data to the cookie' do
        flash = Phase8::Flash.new(req)
        flash[:errors] = 'This is a redirect error'
        flash.store_flash(res)
        cookie = res.cookies.find { |c| c.name == '_rails_lite_flash' }
        deserialized_value = JSON.parse(cookie.value)
        expect(deserialized_value['errors']). to eq 'This is a redirect error'
      end

      it 'does not save flash now data to the cookie' do
        flash = Phase8::Flash.new(req)
        flash[:errors] = 'This is a redirect error'
        flash.now[:errors] = 'This is an error to eq rendered immediately'
        flash.store_flash(res)
        cookie = res.cookies.find { |c| c.name == '_rails_lite_flash' }
        deserialized_value = JSON.parse(cookie.value)
        expect(deserialized_value['errors']). to eq 'This is a redirect error'
      end
    end
  end
end

describe Phase8::ControllerBase do
  before(:all) do
    class CatsController < Phase8::ControllerBase
    end
  end
  after(:all) { Object.send(:remove_const, "CatsController") }

  let(:req) { WEBrick::HTTPRequest.new(Logger: nil) }
  let(:res) { WEBrick::HTTPResponse.new(HTTPVersion: '1.0') }
  let(:cats_controller) { CatsController.new(req, res) }
  let(:args) { ['test', 'text/plain'] }

  describe '#flash' do
    it 'returns a flash instance' do
      expect(cats_controller.flash).to be_a(Phase8::Flash)
    end

    it "returns the same instance on successive invocations" do
      first_result = cats_controller.flash
      expect(cats_controller.flash).to be(first_result)
    end
  end

  # shared_examples_for "storing flash data" do
  #   it 'should store the flash data' do
  #     cats_controller.flash['test_key'] = 'test_value'
  #     #debugger
  #     cats_controller.send(method, *args)
  #     cookie = res.cookies.find { |c| c.name == '_rails_lite_flash' }
  #     deserialized_flash = JSON.parse(cookie.value)
  #     expect(deserialized_flash['test_key']).to eq('test_value')
  #   end
  # end

  describe '#render_content' do
    it 'does not change the flash or set a cookie' do
      cats_controller.flash['test_key'] = 'test_value'
      cats_controller.flash.now[:now_value] = "now"
      old_flash = cats_controller.flash
      old_now = cats_controller.flash.now
      cats_controller.send(:render_content, *args)
      new_cookie = res.cookies.find { |c| c.name == '_rails_lite_flash' }
      expect(new_cookie).to eq nil
      expect(cats_controller.flash).to eq(old_flash)
      expect(cats_controller.flash.now).to eq(old_now)
    end
  end

  describe '#redirect_to' do
    it 'correctly processs flash and flash.now' do
      cats_controller.flash['test_key'] = 'test_value'
      cats_controller.flash.now[:now_value] = "now"
      cats_controller.send(:redirect_to, 'http://appacademy.io')
      cookie = res.cookies.find { |c| c.name == '_rails_lite_flash' }
      deserialized_flash = JSON.parse(cookie.value)
      expect(deserialized_flash['test_key']).to eq('test_value')
      expect(deserialized_flash['now']).to be nil
    end
  end
end
