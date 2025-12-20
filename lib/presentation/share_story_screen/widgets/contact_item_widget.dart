
import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/contact_model.dart';

class ContactItemWidget extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback? onTap;

  ContactItemWidget({
    Key? key,
    required this.contact,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60.h,
            width: 60.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: (contact.isSelected ?? false)
                    ? Color(0xFF52D1C6)
                    : appTheme.transparentCustom,
                width: 2.h,
              ),
            ),
            child: ClipOval(
              child: CustomImageView(
                imagePath: (contact.profileImage == null ||
                        contact.profileImage!.isEmpty)
                    ? ImageConstant.imgEllipse864x64
                    : contact.profileImage!,
                height: 60.h,
                width: 60.h,
                fit: BoxFit.cover,
                placeHolder: ImageConstant.imgImageNotFound,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            contact.name ?? '',
            style: TextStyleHelper.instance.body12Medium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
