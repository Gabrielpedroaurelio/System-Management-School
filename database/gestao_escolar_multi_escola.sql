-- ============================================================
-- ERP ESCOLAR MULTI-ESCOLA — PostgreSQL Professional Schema
-- Versão melhorada combinando gestao_escolar + multi-escola
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- DOMÍNIO: ESCOLAS
-- ============================================================

CREATE TABLE schools (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          VARCHAR(200) NOT NULL,
    code          VARCHAR(50)  UNIQUE NOT NULL,          -- código único por escola
    type          VARCHAR(50)  CHECK (type IN ('Ensino Médio', 'Ensino Superior', 'Creche', 'Ensino Secundário','Ensino Primário')),
    province      VARCHAR(100),
    municipality  VARCHAR(100),
    neighborhood  VARCHAR(100),
    street       varchar(50),
    phone         VARCHAR(50),
    email         VARCHAR(150),
    active        BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- DOMÍNIO: UTILIZADORES / AUTENTICAÇÃO
-- ============================================================
create table permission(
    id UUID primary key default gen_random_uuid(),
    permission varchar(100),
    description text
);
create table role(
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name  VARCHAR(50) NOT NULL CHECK (role_name IN (
                      'Super Administrador',       -- acesso a todas as escolas
                      "Administrador da escola",      -- admin de uma escola
                      'Director',
                        'Director Pedagogico',
                        'Secretário',
                        'Profissional',
                        "Estudante",
                        'Encarregado' )),
    description TEXT

);

CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id     UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    email         VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT,
    role         UUID REFERENCES role(id),
    active        BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

create table permission_user(
    user_id UUID not null references users(id),
    permission_id UUID not null references permission(id),
    primary key(user_id,permission_id)
);

CREATE TABLE login_history (
    id           BIGSERIAL PRIMARY KEY,
    user_id      UUID NOT NULL REFERENCES users(id),
    login_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_at    TIMESTAMP,
    ip_address   inet,
    browser      VARCHAR(100),
    device       VARCHAR(100),
);

-- ============================================================
-- DOMÍNIO: DEPARTAMENTOS / FUNCIONÁRIOS
-- ============================================================

CREATE TABLE departments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name        VARCHAR(150) NOT NULL
);
create table section(
    id          UUID PRIMARY KEY DEFAULT,
    section_name VARCHAR(150) NOT NULL,
    id_department UUID NOT NULL REFERENCES departments(id)
);
create table position(
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    position_name   VARCHAR(150) NOT NULL,
    id_section   UUID NOT NULL REFERENCES section(id)
    base_salary NUMERIC(12,2)
);
-- tabela funcionario
CREATE TABLE employees (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    user_id         UUID REFERENCES users(id),              -- liga ao login
    id_card         VARCHAR(20),                             -- bilhete de identidade
    first_name      VARCHAR(100) NOT NULL,
    middle_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(150),
    phone           VARCHAR(50),
    province        VARCHAR(100),
    municipality    VARCHAR(100),
    neighborhood    VARCHAR(100),
    position_id     UUID REFERENCES position(id),
    section_id   UUID REFERENCES section(id),
    hire_date       DATE,
    active          BOOLEAN DEFAULT TRUE,
    bio             TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Diretores da escola (geral e pedagógico)
ALTER TABLE schools ADD COLUMN director_id          UUID REFERENCES employees(id);
ALTER TABLE schools ADD COLUMN ped_director_id      UUID REFERENCES employees(id);

-- ============================================================
-- DOMÍNIO: ESTRUTURA ACADÉMICA
-- ============================================================

CREATE TABLE education_levels ( -- clasificação geral do nível de ensino
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL                       -- Ex: 7ª, 8ª, ... 12ª, 1º Ano
);

CREATE TABLE training_areas ( --- áreas de formação (útil para ensino superior e médio)
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name        VARCHAR(150) NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE courses ( -- cursos específicos dentro de uma área de formação
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    training_area_id UUID NOT NULL REFERENCES training_areas(id),
    name             VARCHAR(150) NOT NULL,
    duration_years   INT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- melhorar a logica das nota com outra tabela...
create table matrix_grade(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id),
    education_level_id int not null references education_levels(id),
    status boolean default true,
    description text,
    year int not null,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE subjects (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    course_id   UUID NOT NULL REFERENCES courses(id),
    name        VARCHAR(150) NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
create table matrix_subject(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    id_matrix_grade UUID NOT NULL REFERENCES matrix_grade(id),
    subject_id UUID NOT NULL REFERENCES subjects(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rooms (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    room_number      SMALLINT,
    location         VARCHAR(255),
    student_capacity INT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE periods (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name        VARCHAR(50) NOT NULL                        -- Manhã, Tarde, Noite
);

CREATE TABLE academic_years (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    year        varchar(10) NOT NULL,
    start_date  DATE,
    end_date    DATE,
    active      BOOLEAN DEFAULT FALSE,
    UNIQUE (school_id, year)
);

CREATE TABLE classrooms (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    course_id        UUID NOT NULL REFERENCES courses(id),
    room_id          UUID REFERENCES rooms(id),
    level_id         INT  REFERENCES education_levels(id),
    period_id        UUID REFERENCES periods(id),
    name             VARCHAR(50) UNIQUE NOT NULL,           -- Ex: "10ª A Manhã"
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- DOMÍNIO: ALUNOS
-- ============================================================

CREATE TABLE students (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id           UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    user_id             UUID REFERENCES users(id),
    first_name          VARCHAR(100) NOT NULL,
    middle_name         VARCHAR(100),
    last_name           VARCHAR(100) NOT NULL,
    birth_date          DATE,
    gender              VARCHAR(10),
    document_number     VARCHAR(50),
    phone               VARCHAR(50),
    email               VARCHAR(150),
    province            VARCHAR(100),
    municipality        VARCHAR(100),
    neighborhood        VARCHAR(100),
    status              VARCHAR(50) DEFAULT 'Activo' CHECK (status IN ('Activo','Transferido','Desistiu','Concluiu',"Inactivo","Banido")),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(school_id, enrollment_number)
);

-- Dados médicos (útil especialmente para creche)
CREATE TABLE student_medical (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id  UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    allergies   TEXT,
    medications TEXT,
    blood_type  VARCHAR(10),
    notes       TEXT
);

-- Encarregados de educação
CREATE TABLE guardians (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name        VARCHAR(200) NOT NULL,
    phone       VARCHAR(50),
    email       VARCHAR(100),
    id_card     VARCHAR(20) -- bilhete de identidade
);

CREATE TABLE student_guardians (
    student_id  UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    guardian_id UUID NOT NULL REFERENCES guardians(id) ON DELETE CASCADE,
    relation    VARCHAR(50) not null,                                -- Pai, Mãe, Tio...
    PRIMARY KEY (student_id, guardian_id)
);

-- Autorizados a levantar o aluno (creche)
CREATE TABLE authorized_pickups (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id  UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    name        VARCHAR(200) NOT NULL,
    phone       VARCHAR(50),
    relation    VARCHAR(50)
);

-- ============================================================
-- DOMÍNIO: MATRÍCULAS
-- ============================================================

CREATE TABLE enrollments (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enrollment_number varchar(50) not null,
    school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    student_id       UUID NOT NULL REFERENCES students(id),
    classroom_id     UUID NOT NULL REFERENCES classrooms(id),
    status           VARCHAR(50) DEFAULT 'Activo' CHECK (status IN ('Activo','Transferido','Desistiu','Concluiu','Banido')),
    enrolled_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (student_id, academic_year_id)                  -- um aluno por ano letivo
);
-- alter table students add  COLUMN id_enrollment UUID REFERENCES enrollments(id);
-- ============================================================
-- DOMÍNIO: PROFESSORES / DISCIPLINAS
-- ============================================================

CREATE TABLE teacher_subjects (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id     UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    employee_id   UUID NOT NULL REFERENCES employees(id),
    subject_id    UUID NOT NULL REFERENCES subjects(id),
    classroom_id  UUID NOT NULL REFERENCES classrooms(id),
);

-- ============================================================
-- DOMÍNIO: NOTAS
-- ============================================================
create table evaluation_types (-- tipo de avaliação
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name        VARCHAR(50) NOT NULL CHECK (name IN ( 'Prova do Professor do 1º Trimestre','Prova Trimestre do 1º Trimestre','Média das Avaliações Continuas do 1º Trimestre','Prova do Professor do 2º Trimestre','Prova Trimestre do 2º Trimestre','Média das Avaliações Continuas do 2º Trimestre','Prova do Professor do 3º Trimestre','Prova Trimestre do 3º Trimestre','Média das Avaliações Continuas do 3º Trimestre', "Prova do Primeiro Semestre","Prova do Segundo Semestre","Avaliação do Primeiro Semestre","Avaliação do Segundo Semestre")),-- thinking about create a new table to 
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE grades (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    student_id       UUID NOT NULL REFERENCES students(id),
    subject_id       UUID NOT NULL REFERENCES subjects(id),
    teacher_id       UUID NOT NULL REFERENCES employees(id),
    classroom_id     UUID NOT NULL REFERENCES classrooms(id),
    id_evaluationtypes int references evaluation_types(id),
    score            NUMERIC(5, 2),
    recorded_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- DOMÍNIO: FALTAS
-- ============================================================

CREATE TABLE student_attendance (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    student_id   UUID NOT NULL REFERENCES students(id),
    subject_id   UUID NOT NULL REFERENCES subjects(id),
    classroom_id UUID NOT NULL REFERENCES classrooms(id),
    date         DATE NOT NULL,
    justified    BOOLEAN DEFAULT FALSE
);

CREATE TABLE employee_attendance ( -- : faltas dos professores/funcionários
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    employee_id  UUID NOT NULL REFERENCES employees(id),
    subject_id   UUID REFERENCES subjects(id),
    classroom_id UUID REFERENCES classrooms(id),
    date         DATE NOT NULL,
    justified    BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- DOMÍNIO: FINANCEIRO
-- ============================================================
-- ════════════════════════════════════════════
-- 1. SERVIÇOS (base de tudo)
-- ════════════════════════════════════════════
CREATE TABLE services (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name         VARCHAR(150) NOT NULL,        -- ex: 'Propina', 'Matrícula', 'Exame'
    description  TEXT,
    is_monthly   BOOLEAN DEFAULT FALSE,        -- TRUE só para propina
    is_active    BOOLEAN DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ════════════════════════════════════════════
-- 2. PROPINAS (valor por escola/curso/nível)
-- ════════════════════════════════════════════
CREATE TYPE education_level AS ENUM (
    'Pré-Escolar', 'Primária', 'Secundária',
    'Médio', 'Técnico-Profissional',
    'Licenciatura', 'Mestrado', 'Doutoramento'
);

CREATE TABLE tuition_fees (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id        UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    service_id       UUID NOT NULL REFERENCES services(id), -- aponta para "Propina"
    education_level  education_level NOT NULL,
    course_name      VARCHAR(150),
    academic_year    VARCHAR(9) NOT NULL,
    monthly_amount   NUMERIC(12, 2) NOT NULL,
    valid_from       DATE NOT NULL,
    valid_until      DATE,
    notes            TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (school_id, education_level, course_name, academic_year)
);

-- ════════════════════════════════════════════
-- 3. PAGAMENTOS (o que já tinhas + num_months + academic_year)
-- ════════════════════════════════════════════
CREATE TABLE payments (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id    UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    student_id   UUID NOT NULL REFERENCES students(id),
    service_id   UUID NOT NULL REFERENCES services(id),
    amount       NUMERIC(12, 2) NOT NULL,       -- total pago (ex: 3 × 35.000 = 105.000 Kz)
    payment_date DATE NOT NULL,
    method       VARCHAR(50) CHECK (method IN ('Dinheiro','Transferência','Multicaixa','Outro')),
    reference    VARCHAR(100),
    recorded_by  UUID REFERENCES employees(id),

    -- 👇 campos novos para suportar propina mensal
    num_months      SMALLINT DEFAULT 1,         -- quantos meses pagou (1, 2, 4, 6...)
    academic_year   VARCHAR(9),                 -- ex: '2024/2025' (NULL se não for propina)

    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ════════════════════════════════════════════
-- 4. MESES COBERTOS (detalhe do pagamento)
-- ════════════════════════════════════════════
CREATE TABLE payment_months (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id       UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    reference_month  SMALLINT NOT NULL CHECK (reference_month BETWEEN 1 AND 12),
    reference_year   SMALLINT NOT NULL,
    amount_month     NUMERIC(12, 2) NOT NULL,   -- valor desse mês

    UNIQUE (payment_id, reference_month, reference_year)
);

-- Evita pagar o mesmo mês duas vezes para o mesmo serviço/aluno
CREATE UNIQUE INDEX idx_no_duplicate_month
ON payment_months (reference_month, reference_year)
WHERE payment_id IN (
    SELECT id FROM payments
    -- (esta lógica é reforçada melhor via trigger, se quiseres)
);


-- ============================================================
-- DOMÍNIO: BIBLIOTECA
-- ============================================================

CREATE TABLE book_categories (
    id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name     VARCHAR(100) NOT NULL
);

CREATE TABLE books (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id     UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    title         VARCHAR(200) NOT NULL,
    publisher     VARCHAR(150),
    category_id   UUID REFERENCES book_categories(id),
    file_path     TEXT,
    thumb_path text,
    uploaded_by   UUID REFERENCES employees(id),
    uploaded_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- DOMÍNIO: DOCUMENTOS EMITIDOS
-- ============================================================

CREATE TABLE documents (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id     UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    student_id    UUID REFERENCES students(id),
    document_type VARCHAR(100) NOT NULL,                   
    issued_by     UUID REFERENCES employees(id),
    file_path     VARCHAR(255),
    issued_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- DOMÍNIO: AUDITORIA
-- ============================================================

CREATE TABLE audit_logs (
    id             BIGSERIAL PRIMARY KEY,
    school_id      UUID REFERENCES schools(id),
    user_id        UUID REFERENCES users(id),
    table_name     VARCHAR(100) NOT NULL,
    action         VARCHAR(20) NOT NULL CHECK (action IN ('Adicionou','Actuliazou','Eliminou')),
    old_data       JSONB,
    new_data       JSONB,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- ÍNDICES DE PERFORMANCE
-- ============================================================

-- Escola (todas as queries filtram por school_id)
CREATE INDEX idx_users_school           ON users(school_id);
CREATE INDEX idx_employees_school       ON employees(school_id);
CREATE INDEX idx_students_school        ON students(school_id);
CREATE INDEX idx_classrooms_school      ON classrooms(school_id);
CREATE INDEX idx_enrollments_school     ON enrollments(school_id);
CREATE INDEX idx_grades_school          ON grades(school_id);
CREATE INDEX idx_payments_school        ON payments(school_id);
CREATE INDEX idx_attendance_school      ON student_attendance(school_id);
CREATE INDEX idx_audit_school           ON audit_logs(school_id);

-- Queries comuns
CREATE INDEX idx_grades_student         ON grades(student_id, academic_year_id);
CREATE INDEX idx_grades_term            ON grades(student_id, subject_id, term, academic_year_id);
CREATE INDEX idx_attendance_date        ON student_attendance(student_id, date);
CREATE INDEX idx_enrollments_year       ON enrollments(academic_year_id, classroom_id);
CREATE INDEX idx_payments_student       ON payments(student_id, payment_date);
CREATE INDEX idx_login_history_user     ON login_history(user_id, login_at);
CREATE INDEX idx_audit_table            ON audit_logs(table_name, record_id);

-- ============================================================
-- ROW LEVEL SECURITY (multi-escola)
-- Garante isolamento total de dados entre escolas
-- ============================================================

ALTER TABLE students         ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees        ENABLE ROW LEVEL SECURITY;
ALTER TABLE classrooms       ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades           ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_attendance ENABLE ROW LEVEL SECURITY;

-- Exemplo de política: cada utilizador só vê dados da sua escola
-- (aplicar via variável de sessão app.current_school_id)

CREATE POLICY school_isolation ON students
    USING (school_id = current_setting('app.current_school_id')::UUID);

CREATE POLICY school_isolation ON employees
    USING (school_id = current_setting('app.current_school_id')::UUID);

CREATE POLICY school_isolation ON classrooms
    USING (school_id = current_setting('app.current_school_id')::UUID);

CREATE POLICY school_isolation ON grades
    USING (school_id = current_setting('app.current_school_id')::UUID);

CREATE POLICY school_isolation ON payments
    USING (school_id = current_setting('app.current_school_id')::UUID);

CREATE POLICY school_isolation ON student_attendance
    USING (school_id = current_setting('app.current_school_id')::UUID);

-- ============================================================
-- COMENTÁRIOS NAS TABELAS PRINCIPAIS
-- ============================================================

COMMENT ON TABLE schools             IS 'Instituições de ensino (multi-escola)';
COMMENT ON TABLE users               IS 'Contas de autenticação — professores, alunos, admin';
COMMENT ON TABLE employees           IS 'Funcionários: diretores, professores, secretaria';
COMMENT ON TABLE students            IS 'Dados dos alunos matriculados';
COMMENT ON TABLE enrollments         IS 'Matrícula do aluno por ano letivo e turma';
COMMENT ON TABLE academic_years      IS 'Controlo do ano letivo por escola';
COMMENT ON TABLE classrooms          IS 'Turmas com sala, curso, nível, período e ano';
COMMENT ON TABLE teacher_subjects    IS 'Atribuição professor-disciplina-turma por ano';
COMMENT ON TABLE grades              IS 'Notas por trimestre e tipo de avaliação';
COMMENT ON TABLE report_cards        IS 'Boletim com média final por aluno/ano';
COMMENT ON TABLE student_attendance  IS 'Faltas dos alunos por disciplina';
COMMENT ON TABLE employee_attendance IS 'Faltas dos professores/funcionários';
COMMENT ON TABLE payments            IS 'Pagamentos de propinas e serviços';
COMMENT ON TABLE audit_logs          IS 'Histórico completo de INSERT/UPDATE/DELETE';
