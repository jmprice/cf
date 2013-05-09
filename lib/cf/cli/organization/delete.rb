require "cf/cli/organization/base"

module CF::Organization
  class Delete < Base
    desc "Delete an organization"
    group :organizations
    input :organization, :desc => "Organization to delete",
          :aliases => %w{--org -o}, :argument => :optional,
          :from_given => by_name(:organization)
    input :recursive, :desc => "Delete recursively", :alias => "-r",
          :default => false, :forget => true
    input :warn, :desc => "Show warning if it was the last org",
          :default => true
    input :really, :type => :boolean, :forget => true, :hidden => true,
          :default => proc { force? || interact }
    def delete_org
      org = input[:organization]
      return unless input[:really, org]

      is_current = org == client.current_organization

      with_progress("Deleting organization #{c(org.name, :name)}") do
        if input[:recursive]
          org.delete!(:recursive => true)
        else
          org.delete!
        end
      end

      if client.organizations(:depth => 0).size == 1
        return unless input[:warn]

        line
        line c("There are no longer any organizations.", :warning)
        line "You may want to create one with #{c("create-org", :good)}."
      elsif is_current
        invalidate_client
        invoke :target
      end
    rescue CFoundry::AssociationNotEmpty => boom
      line
      line c(boom.description, :bad)
      line c("If you want to delete the organization along with all dependent objects, rerun the command with the #{b("'--recursive'")} flag.", :bad)
      exit_status(1)
    end

    private

    def ask_organization
      orgs = client.organizations(:depth => 0)
      fail "No organizations." if orgs.empty?

      ask("Which organization", :choices => orgs.sort_by(&:name),
          :display => proc(&:name))
    end

    def ask_really(org)
      ask("Really delete #{c(org.name, :name)}?", :default => false)
    end

    def ask_recursive
      ask "Delete #{c("EVERYTHING", :bad)}?", :default => false
    end
  end
end
