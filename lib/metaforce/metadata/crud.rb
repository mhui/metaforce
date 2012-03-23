require 'base64'

module Metaforce
  module Metadata
    module CRUD

      [:create, :update].each do |method|
        define_method(method) do |type, metadata={}|
          metadata = [metadata] unless metadata.is_a?(Array)
          metadata.each_with_index do |m, i|
            template = Metaforce::Metadata::MetadataFile.template(type)
            metadata[i] = template.merge(m) if template
          end
          type = type.to_s.camelcase
          metadata = encode_content(metadata)
          response = @client.request(method) do |soap|
            soap.header = @header
            soap.body = {
              :metadata => metadata,
              :attributes! => { "ins0:metadata" => { "xsi:type" => "wsdl:#{type}" } }
            }
          end
          Transaction.new self, response.body["#{method}_response".to_sym][:result][:id], method
        end
      end

      def delete(type, metadata={})
        type = type.to_s.camelcase
        metadata = [metadata] unless metadata.is_a?(Array)
        response = @client.request(:delete) do |soap|
          soap.header = @header
          soap.body = {
            :metadata => metadata,
            :attributes! => { "ins0:metadata" => { "xsi:type" => "wsdl:#{type}" } }
          }
        end
        Transaction.new self, response.body[:delete_response][:result][:id], :delete
      end

    private

      def encode_content(metadata)
        metadata.each do |m|
          m[:content] = Base64.encode64(m[:content]) if m.has_key?(:content)
        end
        metadata
      end

    end
  end
end

Metaforce::Metadata::Client.send :include, Metaforce::Metadata::CRUD
