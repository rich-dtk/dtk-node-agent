require 'grit'
module DTK
  module NodeAgent
    class GitClient
      def initialize(repo_dir,opts={})
        @repo_dir = repo_dir
        @grit_repo = (opts[:create] ? ::Grit::Repo.init(repo_dir) : ::Grit::Repo.new(repo_dir)) 
      end
      
      def clone_branch(remote_repo,branch,opts={})
        git_command__remote_add(remote_repo,branch)
        git_command__checkout(opts[:sha]||branch)
      end
      
      def pull_and_checkout_branch?(branch,opts={})
        unless remote_branch_exists?(branch)
          git_command__remote_branch_add(branch)
        end
        git_command__fetch()
        git_command__checkout(opts[:sha]||branch)
      end

    private        
      def git_command__remote_add(remote_repo,branch,remote_name=nil)
        remote_name ||= default_remote()
        git_command().remote(git_command_opts(),"add","-t", branch, "-f", remote_name, remote_repo)
      end

      def git_command__remote_branch_add(branch,remote_name=nil)
        remote_name ||= default_remote()
        git_command().remote(git_command_opts(),"set-branches", "--add", remote_name, branch)
      end
      
      def git_command__checkout(ref)
        unless current_branch() == ref
          git_command().checkout(git_command_opts(),ref)
        end
      end
      
      def git_command__fetch()
        git_command().fetch()
      end

      def remote_branch_exists?(branch,remote_name=nil)
        remote_name ||= default_remote()
        remote_branch = "#{remote_name}/#{branch}"
        @grit_repo.remotes.find{|h|h.name == remote_branch} ? true : nil
      end
      
      def current_branch()
        @grit_repo.head.name
      end

      def default_remote()
        'origin'
      end

      def git_command_opts(opts={})
        ret = {:raise => true, :timeout => 60}
        ret.merge!(:chdir => @repo_dir) unless opts[:no_chdir]
      end

      def git_command()
        @grit_repo.git
      end
    end
  end
end

