require 'rubocop'

module RuboCop
  module Cop
    module Style
      class RactorSendReceive < RuboCop::Cop::Base
        MSG = 'Ractor.send detected, '\
              'but no corresponding Ractor.receive found in the Ractor block.'.freeze

        match_send_receive = true

        def_node_search :ractor_new?, <<~PATTERN
          (lvasgn $_value
            (block
              (send (const nil? :Ractor) :new)
              ...
            )
          )
        PATTERN

        def_node_search :ractor_receive?, <<~PATTERN
          (send (const nil? :Ractor) :receive)
        PATTERN
        # def_node_search :match_send?, <<~PATTERN
        #   (lvasgn :r1
        #     (block
        #       (send (const nil? :Ractor) :new)
        #       (args)
        #       ...
        #       (lvasgn _
        #         (send (const nil? :Ractor) :receive))
        #       ...
        #     )
        #   )
        # PATTERN
        # def_node_search :match_send?, <<~PATTERN
        #   (lvasgn :r1 ...)
        # PATTERN

        def on_lvasgn(node)
          p node

          p ractor_new?(node) && ractor_receive?(node)

          if (match = ractor_new?(node))
            p node.children[0]
          end
          match_send_receive = true if match_send?(node)
          # # Check if the send is called on a local variable
          # ractor_variable = node.receiver&.lvar_name
          # return unless ractor_variable

          # # Check if the method is `send`
          # return unless node.method_name == :send

          # # Find the Ractor block corresponding to this variable
          # ractor_block = find_ractor_block(node, ractor_variable)
          # return unless ractor_block

          # # Check if `Ractor.receive` exists in the Ractor block
          # unless find_ractor_receive(ractor_block)
          #   add_offense(node, message: MSG_SEND_NO_RECEIVE)
          # end
        end

        def on_send(node)
          # p node
        end

        private

        # Check if the block is a `Ractor.new` block
        def ractor_block?(node)
          node.send_node&.receiver&.const_name == 'Ractor' && node.send_node.method_name == :new
        end

        # Find the Ractor block corresponding to a variable
        def find_ractor_block(node, ractor_variable)
          node.each_ancestor(:begin).first.each_node(:block).find do |block_node|
            ractor_block?(block_node) && find_ractor_variable(block_node) == ractor_variable
          end
        end

        # Find the Ractor variable assigned to the block
        def find_ractor_variable(node)
          assignment_node = node.each_ancestor(:lvasgn).first
          assignment_node&.children&.first
        end

        # Check if `Ractor.receive` exists within the block
        def find_ractor_receive(node)
          node.body.each_node(:send).any? do |send_node|
            send_node.receiver&.const_name == 'Ractor' && send_node.method_name == :receive
          end
        end
      end
    end
  end
end
