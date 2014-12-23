module Deployinator::Views
  class Index < Layout
    # Public: Gets an array of stacks for use in templating the
    # index page.
    #
    # Retuns an array of non-pinned stacks!
    def get_other_stack_list
      Deployinator.get_stacks
    end
  end
end
