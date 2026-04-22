# app/models/project.py

import uuid
import enum
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Float, Text, Table
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from .skill import Skill

# === GÜNCELLENMİŞ: GENİŞ VE PROFESYONEL 50+ KATEGORİ LİSTESİ ===
class ProjectCategory(str, enum.Enum):
    ARCHITECTURE = "Mimari Tasarım ve Projelendirme"
    INTERIOR_DESIGN = "İç Mimarlık ve Dekorasyon"
    LANDSCAPE = "Peyzaj Mimarlığı ve Çevre Düzenleme"
    URBAN_PLANNING = "Kentsel Tasarım ve Şehir Planlama"
    CIVIL_ENGINEERING = "İnşaat ve Yapı Mühendisliği"
    STRUCTURAL_ANALYSIS = "Statik Proje ve Analiz"
    GEOTECHNICAL = "Geoteknik ve Zemin Mekaniği"
    TRANSPORTATION = "Ulaştırma ve Altyapı Mühendisliği"
    MECHANICAL = "Makine ve Mekanik Tasarım"
    HVAC = "Isıtma, Soğutma ve Havalandırma (HVAC)"
    MANUFACTURING = "İmalat ve Üretim Teknolojileri"
    ELECTRICAL = "Elektrik ve Elektronik Mühendisliği"
    LOW_VOLTAGE = "Zayıf Akım ve Otomasyon Sistemleri"
    RENEWABLE_ENERGY = "Yenilenebilir Enerji Sistemleri"
    MEP = "MEP (Mekanik, Elektrik, Tesisat)"
    INDUSTRIAL_DESIGN = "Endüstriyel Tasarım ve Ürün Geliştirme"
    MOLD_DESIGN = "Kalıp Tasarımı ve İmalat"
    AUTOMOTIVE = "Otomotiv ve Taşıt Tasarımı"
    AEROSPACE = "Havacılık ve Uzay Sanayi"
    MARINE = "Gemi İnşaatı ve Denizcilik"
    PIPING = "Borulama ve Tesisat Tasarımı"
    BIM = "BIM (Yapı Bilgi Modellemesi)"
    BIM_COORDINATION = "BIM Koordinasyon ve Çakışma Analizi"
    THREE_D_VISUALIZATION = "3D Görselleştirme ve Render"
    ANIMATION = "Animasyon ve Hareketli Grafik"
    VFX = "VFX ve Kompozisyon"
    SOFTWARE_DEV = "Yazılım Geliştirme (Web/Mobil/Masaüstü)"
    EMBEDDED_SYSTEMS = "Gömülü Sistemler ve IoT"
    AI_ML = "Yapay Zeka ve Makine Öğrenmesi"
    DATA_SCIENCE = "Veri Bilimi ve Analitiği"
    CYBER_SECURITY = "Siber Güvenlik ve Ağ Yönetimi"
    GAME_DEV = "Oyun Tasarımı ve Geliştirme"
    UI_UX = "Kullanıcı Arayüzü ve Deneyimi (UI/UX)"
    GRAPHIC_DESIGN = "Grafik Tasarım ve Markalama"
    SURVEYING = "Harita ve Kadastro Mühendisliği"
    PHOTOGRAMMETRY = "Fotogrametri ve Lidar Ölçüm"
    MINING = "Maden ve Cevher Hazırlama Mühendisliği"
    CHEMICAL = "Kimya ve Süreç Mühendisliği"
    ENVIRONMENTAL = "Çevre Mühendisliği ve Atık Yönetimi"
    BIOMEDICAL = "Biyomedikal Cihaz Tasarımı"
    ACOUSTICS = "Ses ve Akustik Mühendisliği"
    LIGHTING = "Aydınlatma Tasarımı (Dialux/Relux)"
    RESTORATION = "Restorasyon ve Tarihi Yapı Analizi"
    FURNITURE = "Mobilya ve Obje Tasarımı"
    PACKAGING = "Ambalaj Tasarımı"
    PROJECT_MANAGEMENT = "Proje Yönetimi ve Planlama"
    FIRE_SAFETY = "Yangın Tesisatı ve Güvenliği"
    HYDRAULICS = "Hidrolik ve Pnömatik Sistemler"
    STEEL_DESIGN = "Çelik Yapı Tasarımı ve Detaylandırma"
# ============================================================

class ProjectStatus(enum.Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    PENDING_REVIEW = "pending_review"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

project_skill_association = Table(
    'project_required_skills', Base.metadata,
    Column('project_id', UUID(as_uuid=True), ForeignKey('projects.id'), primary_key=True),
    Column('skill_id', UUID(as_uuid=True), ForeignKey('skills.id'), primary_key=True)
)

class ProjectRevision(Base):
    __tablename__ = "project_revisions"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False)
    request_reason = Column(Text, nullable=False)
    requested_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    project = relationship("Project", back_populates="revisions")

class Project(Base):
    __tablename__ = "projects"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    title = Column(String, index=True, nullable=False)
    description = Column(Text, nullable=False)
    
    # Enum değerlerini veritabanında String olarak saklıyoruz, 
    # ancak kod tarafında Enum class'ı ile doğrulama yapacağız.
    category = Column(String, index=True, nullable=False)
    
    budget_min = Column(Integer, nullable=True)
    budget_max = Column(Integer, nullable=True)
    deadline = Column(DateTime(timezone=True), nullable=True)
    status = Column(String, default=ProjectStatus.OPEN.value)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    owner = relationship("User", back_populates="projects")
    applications = relationship("Application", back_populates="project", cascade="all, delete-orphan")
    required_skills = relationship("Skill", secondary=project_skill_association, backref="projects")
    reviews = relationship("Review", back_populates="project")
    revisions = relationship("ProjectRevision", back_populates="project", order_by="desc(ProjectRevision.requested_at)", cascade="all, delete-orphan")

    @property
    def accepted_application(self):
        for app in self.applications:
            if str(app.status) == "accepted":
                return app
        return None