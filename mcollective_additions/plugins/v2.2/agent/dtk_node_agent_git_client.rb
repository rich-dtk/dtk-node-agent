require 'grit'
module DTK
  module NodeAgent
    class GitClient
      def initialize(repo_dir,opts={})
        @repo_dir = repo_dir
        @grit_repo = (opts[:create] ? ::Grit::Repo.init(repo_dir) : ::Grit::Repo.new(repo_dir)) 
      end
      
      def clone_branch(remote_repo,branch,opts={})
        Dir.chdir(@repo_dir) do
          git_command__remote_add(remote_repo,branch)
          git_command__checkout(opts[:sha]||branch)
        end
      end
      
      def pull_and_checkout_branch?(remote_repo,branch,opts={})
        Dir.chdir(@repo_dir) do
          unless remote_branch_exists?(branch)
            git_command__remote_add(remote_repo,branch)
          end
          git_command__checkout(opts[:sha]||branch)
        end
      end

    private        
      def git_command__remote_add(remote_repo,branch)
        git_command().remote(git_command_opts(),"add","-t", branch, "-f", "origin", remote_repo)
      end
      
      def git_command__checkout(ref)
        unless current_branch() == ref
          git_command().checkout(git_command_opts(),ref)
        end
      end
      
      def remote_branch_exists?(branch)
        @grit_repo.remotes.find{|h|h.name == branch} ? true : nil
      end
      
      def current_branch()
        @grit_repo.head.name
      end
      
      def self.git_command_opts()
        {:raise => true, :timeout => 60}
      end
      def git_command_opts()
        self.class.git_command_opts()
      end
      def git_command()
        @grit_repo.git
      end
    end
  end
end

