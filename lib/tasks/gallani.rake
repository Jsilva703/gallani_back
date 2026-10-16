namespace :gallani do
  desc "Create the first administrative user from environment variables"
  task bootstrap_admin: :environment do
    email = ENV.fetch("ADMIN_EMAIL").strip.downcase
    password = ENV.fetch("ADMIN_PASSWORD")
    name = ENV.fetch("ADMIN_NAME", "Administrador")

    abort "ADMIN_PASSWORD deve ter pelo menos 8 caracteres" if password.length < 8

    user = User.find_or_initialize_by(email: email)
    user.assign_attributes(
      name: name,
      role: "admin",
      active: true,
      professional: nil,
      password: password,
      password_confirmation: password
    )
    user.save!

    puts "Administrador preparado: #{user.email}"
  end

  desc "Generate an integration token for Nexa"
  task integration_token: :environment do
    label = ENV.fetch("TOKEN_LABEL", "nexa")
    _record, raw_token = ApiToken.generate!(label: label)

    puts "Token criado para #{label}. Salve agora; ele não será exibido novamente:"
    puts raw_token
  end

  desc "Delete expired user sessions"
  task cleanup_sessions: :environment do
    deleted = UserSession.where("expires_at <= ?", Time.current).delete_all
    puts "#{deleted} sessões expiradas removidas"
  end
end
