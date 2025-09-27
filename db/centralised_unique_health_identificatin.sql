-- PostgreSQL DDL for Centralized Hospital Database
BEGIN;

-- Create UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. ROLES TABLE
-- Defines user roles in the system (admin, doctor, nurse, patient, etc.)
CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 2. INSTITUTIONS TABLE  
-- Healthcare facilities/hospitals/clinics in the system
CREATE TABLE institutions (
    institution_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    contact VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 3. PATIENTS TABLE
-- Patient demographic and contact information
CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    uhid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_date DATE NOT NULL,
    sex VARCHAR(10) NOT NULL CHECK (sex IN ('Male', 'Female', 'Other')),
    phone VARCHAR(20),
    address TEXT,
    has_allergy BOOLEAN DEFAULT FALSE,
    primary_allergy VARCHAR(200),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. DOCTORS TABLE
-- Healthcare providers/physicians in the system
CREATE TABLE doctors (
    doctor_id SERIAL PRIMARY KEY,
    staff_number VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    specialty VARCHAR(100),
    contact VARCHAR(100),
    institution_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (institution_id) REFERENCES institutions(institution_id) ON DELETE CASCADE
);

-- 5. APPOINTMENTS TABLE
-- Scheduled patient-doctor meetings
CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    institution_id INTEGER NOT NULL,
    scheduled_at TIMESTAMP NOT NULL,
    reason TEXT,
    status VARCHAR(30) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no-show')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (institution_id) REFERENCES institutions(institution_id) ON DELETE CASCADE
);

-- 6. PRESCRIPTIONS TABLE
-- Medication prescriptions given during appointments
CREATE TABLE prescriptions (
    rx_id SERIAL PRIMARY KEY,
    appointment_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    medicine_name VARCHAR(150) NOT NULL,
    dose VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    instructions TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
);

-- 7. LAB_RESULTS TABLE
-- Laboratory test results and reports
CREATE TABLE lab_results (
    lab_id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    appointment_id INTEGER,
    test_name VARCHAR(150) NOT NULL,
    test_code VARCHAR(50),
    test_date DATE NOT NULL,
    result_value TEXT,
    units VARCHAR(50),
    image_link VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL
);

-- 8. IMAGING TABLE
-- Medical imaging records (X-rays, CT scans, MRIs, etc.)
CREATE TABLE imaging (
    image_id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    appointment_id INTEGER,
    image_type VARCHAR(50) NOT NULL,
    image_path VARCHAR(255) NOT NULL,
    taken_at TIMESTAMP NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL
);

-- 9. USERS TABLE
-- System users with authentication and role information
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL,
    institution_id INTEGER,
    doctor_id INTEGER,
    patient_id INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    FOREIGN KEY (institution_id) REFERENCES institutions(institution_id) ON DELETE SET NULL,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE SET NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE SET NULL,
    -- Ensure user is linked to appropriate entity based on role
    CONSTRAINT user_entity_check CHECK (
        (role_id IN (SELECT role_id FROM roles WHERE role_name IN ('doctor', 'physician')) AND doctor_id IS NOT NULL) OR
        (role_id IN (SELECT role_id FROM roles WHERE role_name = 'patient') AND patient_id IS NOT NULL) OR
        (role_id NOT IN (SELECT role_id FROM roles WHERE role_name IN ('doctor', 'physician', 'patient')))
    )
);

-- 10. API_ENDPOINTS TABLE
-- API endpoints configuration for system integration
CREATE TABLE api_endpoints (
    endpoint_id SERIAL PRIMARY KEY,
    http_method VARCHAR(10) NOT NULL CHECK (http_method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH')),
    route VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    related_table VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

-- CREATE INDEXES for better query performance
CREATE INDEX idx_patients_uhid ON patients(uhid);
CREATE INDEX idx_patients_name ON patients(first_name, last_name);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_appointments_date ON appointments(scheduled_at);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX idx_prescriptions_appointment ON prescriptions(appointment_id);
CREATE INDEX idx_lab_results_patient ON lab_results(patient_id);
CREATE INDEX idx_lab_results_date ON lab_results(test_date);
CREATE INDEX idx_imaging_patient ON imaging(patient_id);
CREATE INDEX idx_imaging_date ON imaging(taken_at);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_doctors_staff_number ON doctors(staff_number);
CREATE INDEX idx_doctors_institution ON doctors(institution_id);

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for auto-updating timestamps
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default roles
INSERT INTO roles (role_name, description) VALUES 
    ('admin', 'System administrator with full access'),
    ('doctor', 'Medical doctor/physician'),
    ('nurse', 'Nursing staff'),
    ('patient', 'Patient user account'),
    ('lab_tech', 'Laboratory technician'),
    ('radiologist', 'Medical imaging specialist'),
    ('receptionist', 'Front desk/appointment scheduling staff');

COMMIT;
