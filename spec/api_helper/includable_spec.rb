require 'spec_helper'

describe APIHelper::Includable do
  describe ".include_param_desc" do
    it "returns a string" do
      expect(APIHelper::Includable.include_param_desc).to be_a(String)
    end
  end
end
