module ModelsHelper
  def load_models
    define_constant :PublisherModel do
      include Mongoid::Document
      include Promiscuous::Publisher

      field :group
      field :other_collection_id

      publish :group, :other_collection_id
    end
  end
end
