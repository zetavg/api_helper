require 'spec_helper'

describe APIHelper::Paginatable do
  describe ".per_page_param_desc" do
    it "returns a string" do
      expect(APIHelper::Paginatable.per_page_param_desc).to be_a(String)
    end
  end

  describe ".page_param_desc" do
    it "returns a string" do
      expect(APIHelper::Paginatable.page_param_desc).to be_a(String)
    end
  end
end
