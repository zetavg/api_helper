require 'spec_helper'

describe APIHelper::Fieldsettable do
  describe ".fields_param_desc" do
    it "returns a string" do
      expect(APIHelper::Fieldsettable.fields_param_desc).to be_a(String)
    end
  end
end
