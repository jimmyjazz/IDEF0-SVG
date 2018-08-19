module IDEF0
  module StringCommentDetection
    def comment?
      start_with?("#")
    end
  end

  String.send(:include, StringCommentDetection)
end
