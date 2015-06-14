require 'spec_helper'

describe APIHelper::Sortable do
  describe ".sort_param_desc" do
    it "returns a string" do
      expect(APIHelper::Sortable.sort_param_desc).to be_a(String)
    end
  end
end
