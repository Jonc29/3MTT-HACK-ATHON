-- PostgreSQL DDL for Centralized Hospital Database

CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    uhid VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10),
    phone VARCHAR(20),
    address TEXT
);

CREATE TABLE hospitals (
    hospital_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100)
);

CREATE TABLE medical_records (
    record_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id) ON DELETE CASCADE,
    hospital_id INT REFERENCES hospitals(hospital_id) ON DELETE CASCADE,
    diagnosis TEXT NOT NULL,
    treatment TEXT,
    date_of_visit DATE DEFAULT CURRENT_DATE
);

CREATE TABLE prescriptions (
    prescription_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id) ON DELETE CASCADE,
    medicine_name VARCHAR(100) NOT NULL,
    dosage VARCHAR(50),
    prescribed_date DATE DEFAULT CURRENT_DATE
);
