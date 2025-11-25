from app.database import Base

# Bağımsız Modeller
from .skill import Skill
from .user import User

# Bağımlı Modeller (Sıralama Önemli)
from .project import Project, ProjectStatus, ProjectRevision
from .application import Application, ApplicationStatus
from .showcase import ShowcasePost, PostLike, PostComment, CommentLike
from .report import Report, ReportReason, ReportStatus  # <--- BU SATIR ŞART
from .audit import AuditLog
from .message import Message
from .notification import Notification
from .portfolio import PortfolioItem 
from .question import Question
from .choice import Choice
from .skill_test import SkillTest
from .test_result import TestResult
from .review import Review
from .work_experience import WorkExperience
from .recommendation import ProjectRecommendation