# app/schemas/__init__.py

# 1. Forward Reference kullanan ve kullanılan tüm şemaları import et
from .user import User, UserCreate, UserUpdate, UserSummary, PasswordUpdate, UserInResponse, UserBase, UserRole
from .review import Review, ReviewCreate, ReviewBase, ProjectInReview
from .project import Project, ProjectCreate, ProjectUpdate, ProjectInReview, ProjectBase, ProjectStatus
from .skill import Skill, SkillCreate, SkillBase
from .portfolio import PortfolioItem, PortfolioItemCreate, PortfolioItemBase
from .work_experience import WorkExperience, WorkExperienceCreate, WorkExperienceBase, WorkExperienceUpdate
from .test_result import TestResult, TestResultBase, TestResultCreate, TestStatus, TestSubmission, SkillTestSimple
from .application import Application, ApplicationCreate, ApplicationStatus, ApplicationStatusUpdate, ProjectInApplication, ApplicationBase, ApplicationUpdate
from .message import Message, MessageBase, MessageCreate, MessageUpdate, BaseModel
from .notification import Notification, NotificationBase, UserSummary, NotificationType, UnreadNotificationCount, MarkAllReadResponse
from .skill import Skill, SkillBase, SkillCreate
from .skill_test import SkillTest, SkillTestBase, SkillTestCreate, SkillTestSimple
from .showcase import ShowcasePost, ShowcasePostBase, ShowcasePostCreate, ShowcasePostUpdate, UserSummary, ShowcasePostInit, ShowcasePostInitResponse, ProcessingStatus
from .recommendation import ProjectRecommendationOut
# 2. Tüm şemalar import edildikten sonra, Forward Reference'ları çöz
User.model_rebuild()
Review.model_rebuild()
Project.model_rebuild()
Application.model_rebuild()
Review.model_rebuild()
ProjectInApplication.model_rebuild()