require 'spec_helper'

describe APIHelper::Filterable do
  describe ".filter_param_desc" do
    it "returns a string" do
      expect(APIHelper::Filterable.filter_param_desc).to be_a(String)
    end
  end
end
