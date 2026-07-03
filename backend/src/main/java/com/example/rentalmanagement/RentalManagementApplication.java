package com.example.rentalmanagement;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.example.rentalmanagement.common.enums.UserStatus;
import com.example.rentalmanagement.user.Role;
import com.example.rentalmanagement.user.User;
import com.example.rentalmanagement.user.repository.RoleRepository;
import com.example.rentalmanagement.user.repository.UserRepository;

@SpringBootApplication
@EnableJpaAuditing
@EnableScheduling
public class RentalManagementApplication {
    public static void main(String[] args) {
        SpringApplication.run(RentalManagementApplication.class, args);
    }

    @Bean
    CommandLineRunner bootstrapAdmin(
            RoleRepository roles,
            UserRepository users,
            PasswordEncoder passwordEncoder,
            @Value("${app.bootstrap.admin-username:admin}") String username,
            @Value("${app.bootstrap.admin-password:Admin@123}") String password
    ) {
        return args -> {
            Role adminRole = roles.findByCode("ADMIN")
                    .orElseGet(() -> roles.save(new Role("ADMIN", "Administrator", "Building owner or manager")));
            roles.findByCode("TENANT")
                    .orElseGet(() -> roles.save(new Role("TENANT", "Tenant", "Primary tenant account")));
            if (users.findByUsername(username).isEmpty()) {
                User user = new User();
                user.username = username;
                user.passwordHash = passwordEncoder.encode(password);
                user.role = adminRole;
                user.status = UserStatus.ACTIVE;
                user.mustChangePassword = false;
                users.save(user);
            }
        };
    }
}
